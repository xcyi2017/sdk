// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_LINUX)

#include "bin/file.h"

#include <errno.h>  // NOLINT
#include <fcntl.h>  // NOLINT
#include <sys/stat.h>  // NOLINT
#include <sys/types.h>  // NOLINT
#include <sys/sendfile.h>  // NOLINT
#include <unistd.h>  // NOLINT
#include <libgen.h>  // NOLINT

#include "bin/builtin.h"
#include "bin/log.h"


namespace dart {
namespace bin {

class FileHandle {
 public:
  explicit FileHandle(int fd) : fd_(fd) { }
  ~FileHandle() { }
  int fd() const { return fd_; }
  void set_fd(int fd) { fd_ = fd; }

 private:
  int fd_;

  DISALLOW_COPY_AND_ASSIGN(FileHandle);
};


File::~File() {
  // Close the file (unless it's a standard stream).
  if (handle_->fd() > STDERR_FILENO) {
    Close();
  }
  delete handle_;
}


void File::Close() {
  ASSERT(handle_->fd() >= 0);
  int err = TEMP_FAILURE_RETRY(close(handle_->fd()));
  if (err != 0) {
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    Log::PrintErr("%s\n", strerror_r(errno, error_buf, kBufferSize));
  }
  handle_->set_fd(kClosedFd);
}


bool File::IsClosed() {
  return handle_->fd() == kClosedFd;
}


int64_t File::Read(void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(read(handle_->fd(), buffer, num_bytes));
}


int64_t File::Write(const void* buffer, int64_t num_bytes) {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(write(handle_->fd(), buffer, num_bytes));
}


off64_t File::Position() {
  ASSERT(handle_->fd() >= 0);
  return lseek64(handle_->fd(), 0, SEEK_CUR);
}


bool File::SetPosition(off64_t position) {
  ASSERT(handle_->fd() >= 0);
  return lseek64(handle_->fd(), position, SEEK_SET) >= 0;
}


bool File::Truncate(off64_t length) {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(ftruncate64(handle_->fd(), length) != -1);
}


bool File::Flush() {
  ASSERT(handle_->fd() >= 0);
  return TEMP_FAILURE_RETRY(fsync(handle_->fd()) != -1);
}


off64_t File::Length() {
  ASSERT(handle_->fd() >= 0);
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(fstat64(handle_->fd(), &st)) == 0) {
    return st.st_size;
  }
  return -1;
}


File* File::Open(const char* name, FileOpenMode mode) {
  // Report errors for non-regular files.
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(stat64(name, &st)) == 0) {
    // Only accept regular files and character devices.
    if (!S_ISREG(st.st_mode) && !S_ISCHR(st.st_mode)) {
      errno = (S_ISDIR(st.st_mode)) ? EISDIR : ENOENT;
      return NULL;
    }
  }
  int flags = O_RDONLY;
  if ((mode & kWrite) != 0) {
    flags = (O_RDWR | O_CREAT);
  }
  if ((mode & kTruncate) != 0) {
    flags = flags | O_TRUNC;
  }
  flags |= O_CLOEXEC;
  int fd = TEMP_FAILURE_RETRY(open64(name, flags, 0666));
  if (fd < 0) {
    return NULL;
  }
  if (((mode & kWrite) != 0) && ((mode & kTruncate) == 0)) {
    off64_t position = lseek64(fd, 0, SEEK_END);
    if (position < 0) {
      return NULL;
    }
  }
  return new File(new FileHandle(fd));
}


File* File::OpenStdio(int fd) {
  if (fd < 0 || 2 < fd) return NULL;
  return new File(new FileHandle(fd));
}


bool File::Exists(const char* name) {
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(stat64(name, &st)) == 0) {
    return S_ISREG(st.st_mode);
  } else {
    return false;
  }
}


bool File::Create(const char* name) {
  int fd = TEMP_FAILURE_RETRY(
      open64(name, O_RDONLY | O_CREAT | O_CLOEXEC, 0666));
  if (fd < 0) {
    return false;
  }
  return (close(fd) == 0);
}


bool File::CreateLink(const char* name, const char* target) {
  int status = TEMP_FAILURE_RETRY(symlink(target, name));
  return (status == 0);
}


bool File::Delete(const char* name) {
  File::Type type = File::GetType(name, true);
  if (type == kIsFile) {
    return TEMP_FAILURE_RETRY(unlink(name)) == 0;
  } else if (type == kIsDirectory) {
    errno = EISDIR;
  } else {
    errno = ENOENT;
  }
  return false;
}


bool File::DeleteLink(const char* name) {
  File::Type type = File::GetType(name, false);
  if (type == kIsLink) {
    return TEMP_FAILURE_RETRY(unlink(name)) == 0;
  }
  errno = EINVAL;
  return false;
}


bool File::Rename(const char* old_path, const char* new_path) {
  File::Type type = File::GetType(old_path, true);
  if (type == kIsFile) {
    return TEMP_FAILURE_RETRY(rename(old_path, new_path)) == 0;
  } else if (type == kIsDirectory) {
    errno = EISDIR;
  } else {
    errno = ENOENT;
  }
  return false;
}


bool File::RenameLink(const char* old_path, const char* new_path) {
  File::Type type = File::GetType(old_path, false);
  if (type == kIsLink) {
    return TEMP_FAILURE_RETRY(rename(old_path, new_path)) == 0;
  } else if (type == kIsDirectory) {
    errno = EISDIR;
  } else {
    errno = EINVAL;
  }
  return false;
}


bool File::Copy(const char* old_path, const char* new_path) {
  File::Type type = File::GetType(old_path, true);
  if (type == kIsFile) {
    struct stat64 st;
    if (TEMP_FAILURE_RETRY(stat64(old_path, &st)) != 0) {
      return false;
    }
    int old_fd = TEMP_FAILURE_RETRY(open64(old_path, O_RDONLY | O_CLOEXEC));
    if (old_fd < 0) {
      return false;
    }
    int new_fd = TEMP_FAILURE_RETRY(
        open64(new_path, O_WRONLY | O_TRUNC | O_CREAT | O_CLOEXEC, st.st_mode));
    if (new_fd < 0) {
      VOID_TEMP_FAILURE_RETRY(close(old_fd));
      return false;
    }
    off64_t offset = 0;
    int bytes = 1;
    while (bytes > 0) {
      // Loop to ensure we copy everything, and not only up to 2GB.
      bytes = TEMP_FAILURE_RETRY(
          sendfile64(new_fd, old_fd, &offset, kMaxUint32));
    }
    if (bytes < 0) {
      int e = errno;
      VOID_TEMP_FAILURE_RETRY(close(old_fd));
      VOID_TEMP_FAILURE_RETRY(close(new_fd));
      VOID_TEMP_FAILURE_RETRY(unlink(new_path));
      errno = e;
      return false;
    }
    return true;
  } else if (type == kIsDirectory) {
    errno = EISDIR;
  } else {
    errno = ENOENT;
  }
  return false;
}


off64_t File::LengthFromPath(const char* name) {
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(stat64(name, &st)) == 0) {
    return st.st_size;
  }
  return -1;
}


void File::Stat(const char* name, int64_t* data) {
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(stat64(name, &st)) == 0) {
    if (S_ISREG(st.st_mode)) {
      data[kType] = kIsFile;
    } else if (S_ISDIR(st.st_mode)) {
      data[kType] = kIsDirectory;
    } else if (S_ISLNK(st.st_mode)) {
      data[kType] = kIsLink;
    } else {
      data[kType] = kDoesNotExist;
    }
    data[kCreatedTime] = st.st_ctime;
    data[kModifiedTime] = st.st_mtime;
    data[kAccessedTime] = st.st_atime;
    data[kMode] = st.st_mode;
    data[kSize] = st.st_size;
  } else {
    data[kType] = kDoesNotExist;
  }
}


time_t File::LastModified(const char* name) {
  struct stat64 st;
  if (TEMP_FAILURE_RETRY(stat64(name, &st)) == 0) {
    return st.st_mtime;
  }
  return -1;
}


char* File::LinkTarget(const char* pathname) {
  struct stat64 link_stats;
  if (lstat64(pathname, &link_stats) != 0) return NULL;
  if (!S_ISLNK(link_stats.st_mode)) {
    errno = ENOENT;
    return NULL;
  }
  size_t target_size = link_stats.st_size;
  char* target_name = reinterpret_cast<char*>(malloc(target_size + 1));
  size_t read_size = readlink(pathname, target_name, target_size + 1);
  if (read_size != target_size) {
    free(target_name);
    return NULL;
  }
  target_name[target_size] = '\0';
  return target_name;
}


bool File::IsAbsolutePath(const char* pathname) {
  return (pathname != NULL && pathname[0] == '/');
}


char* File::GetCanonicalPath(const char* pathname) {
  char* abs_path = NULL;
  if (pathname != NULL) {
    do {
      abs_path = realpath(pathname, NULL);
    } while (abs_path == NULL && errno == EINTR);
    ASSERT(abs_path == NULL || IsAbsolutePath(abs_path));
  }
  return abs_path;
}


const char* File::PathSeparator() {
  return "/";
}


const char* File::StringEscapedPathSeparator() {
  return "/";
}


File::StdioHandleType File::GetStdioHandleType(int fd) {
  ASSERT(0 <= fd && fd <= 2);
  struct stat64 buf;
  int result = fstat64(fd, &buf);
  if (result == -1) {
    const int kBufferSize = 1024;
    char error_buf[kBufferSize];
    FATAL2("Failed stat on file descriptor %d: %s", fd,
           strerror_r(errno, error_buf, kBufferSize));
  }
  if (S_ISCHR(buf.st_mode)) return kTerminal;
  if (S_ISFIFO(buf.st_mode)) return kPipe;
  if (S_ISSOCK(buf.st_mode)) return kSocket;
  if (S_ISREG(buf.st_mode)) return kFile;
  return kOther;
}


File::Type File::GetType(const char* pathname, bool follow_links) {
  struct stat64 entry_info;
  int stat_success;
  if (follow_links) {
    stat_success = TEMP_FAILURE_RETRY(stat64(pathname, &entry_info));
  } else {
    stat_success = TEMP_FAILURE_RETRY(lstat64(pathname, &entry_info));
  }
  if (stat_success == -1) return File::kDoesNotExist;
  if (S_ISDIR(entry_info.st_mode)) return File::kIsDirectory;
  if (S_ISREG(entry_info.st_mode)) return File::kIsFile;
  if (S_ISLNK(entry_info.st_mode)) return File::kIsLink;
  return File::kDoesNotExist;
}


File::Identical File::AreIdentical(const char* file_1, const char* file_2) {
  struct stat64 file_1_info;
  struct stat64 file_2_info;
  if (TEMP_FAILURE_RETRY(lstat64(file_1, &file_1_info)) == -1 ||
      TEMP_FAILURE_RETRY(lstat64(file_2, &file_2_info)) == -1) {
    return File::kError;
  }
  return (file_1_info.st_ino == file_2_info.st_ino &&
          file_1_info.st_dev == file_2_info.st_dev) ?
      File::kIdentical :
      File::kDifferent;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_LINUX)
