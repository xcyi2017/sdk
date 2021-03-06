// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PrivateCollisionInMixinApplicationTest);
  });
}

@reflectiveTest
class PrivateCollisionInMixinApplicationTest extends DriverResolutionTest {
  test_class_interfaceAndMixin_same() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo() {}
}
''');

    await assertNoErrorsInCode('''
import 'a.dart';

class C implements A {}
class D extends C with A {}
''');
  }

  test_class_mixinAndMixin() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo() {}
}

class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends Object with A, B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 49, 1),
    ]);
  }

  test_class_mixinAndMixin_indirect() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo() {}
}

class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends Object with A {}
class D extends C with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 74, 1),
    ]);
  }

  test_class_superclassAndMixin_getter2() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  int get _foo => 0;
}

class B {
  int get _foo => 0;
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends A with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 41, 1),
    ]);
  }

  test_class_superclassAndMixin_method2() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo() {}
}

class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends A with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 41, 1),
    ]);
  }

  test_class_superclassAndMixin_same() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends A with A {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 41, 1),
    ]);
  }

  test_class_superclassAndMixin_sameLibrary() async {
    await assertNoErrorsInCode('''
class A {
  void _foo() {}
}

class B {
  void _foo() {}
}

class C extends Object with A, B {}
''');
  }

  test_class_superclassAndMixin_setter2() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  set _foo(int _) {}
}

class B {
  set _foo(int _) {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C extends A with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 41, 1),
    ]);
  }

  test_classTypeAlias_mixinAndMixin() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo() {}
}

class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C = Object with A, B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 43, 1),
    ]);
  }

  test_classTypeAlias_mixinAndMixin_indirect() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo() {}
}

class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C = Object with A;
class D = C with B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 60, 1),
    ]);
  }

  test_classTypeAlias_superclassAndMixin() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo() {}
}

class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C = A with B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 35, 1),
    ]);
  }

  test_classTypeAlias_superclassAndMixin_same() async {
    newFile('/test/lib/a.dart', content: r'''
class A {
  void _foo() {}
}

class B {
  void _foo() {}
}
''');

    await assertErrorsInCode('''
import 'a.dart';

class C = A with A;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 35, 1),
    ]);
  }
}
