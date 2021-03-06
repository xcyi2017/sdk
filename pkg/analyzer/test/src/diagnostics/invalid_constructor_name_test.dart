// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidConstructorNameTest);
  });
}

@reflectiveTest
class InvalidConstructorNameTest extends DriverResolutionTest {
  test_notEnclosingClassName_defined() async {
    await assertErrorsInCode(r'''
class A {
  B() : super();
}
class B {}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, 12, 1),
    ]);
  }

  test_notEnclosingClassName_undefined() async {
    await assertErrorsInCode(r'''
class A {
  B() : super();
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, 12, 1),
    ]);
  }
}
