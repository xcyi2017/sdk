part of analyzer;

/**
 * Helper for formatting [AnalysisError]s.
 * The two format options are a user consumable format and a machine consumable format.
 */
class _ErrorFormatter {
  StringSink out;
  CommandLineOptions options;

  _ErrorFormatter(this.out, this.options);

  void startAnalysis() {
    if (!options.machineFormat) {
      out.writeln("Analyzing ${options.sourceFiles}...");
    }
  }

  void formatErrors(List<AnalysisErrorInfo> errorInfos) {
    var errors = new List<AnalysisError>();
    var errorToLine = new Map<AnalysisError, LineInfo>();
    for (AnalysisErrorInfo errorInfo in errorInfos) {
      for (AnalysisError error in errorInfo.errors) {
        errors.add(error);
        errorToLine[error] = errorInfo.lineInfo;
      }
    }
    // sort errors
    errors.sort((AnalysisError error1, AnalysisError error2) {
      // severity
      int compare = error2.errorCode.errorSeverity.compareTo(error1.errorCode.errorSeverity);
      if (compare != 0) {
        return compare;
      }
      // path
      compare = Comparable.compare(error1.source.fullName.toLowerCase(), error2.source.fullName.toLowerCase());
      if (compare != 0) {
        return compare;
      }
      // offset
      return error1.offset - error2.offset;
    });
    // format errors
    int errorCount = 0;
    int warnCount = 0;
    for (AnalysisError error in errors) {
      if (error.errorCode.errorSeverity == ErrorSeverity.ERROR) {
        errorCount++;
      } else if (error.errorCode.errorSeverity == ErrorSeverity.WARNING) {
        if (options.warningsAreFatal) {
          errorCount++;
        } else {
          warnCount++;
        }
      }
      formatError(errorToLine, error);
    }
    // print statistics
    if (!options.machineFormat) {
      if (errorCount != 0 && warnCount != 0) {
        out.write(errorCount);
        out.write(' ');
        out.write(pluralize("error", errorCount));
        out.write(' and ');
        out.write(warnCount);
        out.write(' ');
        out.write(pluralize("warning", warnCount));
        out.writeln(' found.');
      } else if (errorCount != 0) {
        out.write(errorCount);
        out.write(' ');
        out.write(pluralize("error", errorCount));
        out.writeln(' found.');
      } else if (warnCount != 0) {
        out.write(warnCount);
        out.write(' ');
        out.write(pluralize("warning", warnCount));
        out.writeln(' found.');
      } else {
        out.writeln("No issues found.");
      }
    }
  }

  void formatError(Map<AnalysisError, LineInfo> errorToLine, AnalysisError error) {
    Source source = error.source;
    LineInfo_Location location = errorToLine[error].getLocation(error.offset);
    int length = error.length;
    var severity = error.errorCode.errorSeverity;
    if (options.machineFormat) {
      if (severity == ErrorSeverity.WARNING && options.warningsAreFatal) {
        severity = ErrorSeverity.ERROR;
      }
      out.write(severity);
      out.write('|');
      out.write(error.errorCode.type);
      out.write('|');
      out.write(error.errorCode);
      out.write('|');
      out.write(escapePipe(source.fullName));
      out.write('|');
      out.write(location.lineNumber);
      out.write('|');
      out.write(location.columnNumber);
      out.write('|');
      out.write(length);
      out.write('|');
      out.writeln(escapePipe(error.message));
    } else {
      // [warning] 'foo' is not a method or function (/Users/devoncarew/temp/foo.dart:-1:-1)
      out.write('[');
      out.write(severity.displayName);
      out.write('] ');
      out.write(error.message);
      out.write(' (');
      out.write(source.fullName);
      out.write(':');
      out.write(location.lineNumber);
      out.write(':');
      out.write(location.columnNumber);
      out.writeln(')');
    }
  }

  static String escapePipe(String input) {
    var result = new StringBuffer();
    for (var c in input.codeUnits) {
      if (c == '\\' || c == '|') {
        result.write('\\');
      }
      result.writeCharCode(c);
    }
    return result.toString();
  }

  static String pluralize(String word, int count) {
    if (count == 1) {
      return word;
    } else {
      return word + "s";
    }
  }
}
