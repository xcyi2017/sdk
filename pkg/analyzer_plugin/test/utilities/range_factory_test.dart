// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SourceRangesTest);
  });
}

@reflectiveTest
class SourceRangesTest extends AbstractSingleUnitTest {
  test_elementName() async {
    await resolveTestUnit('class ABC {}');
    Element element = findElement('ABC');
    expect(range.elementName(element), SourceRange(6, 3));
  }

  test_endEnd() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction =
        testUnit.declarations[0] as FunctionDeclaration;
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(range.endEnd(mainName, mainBody), SourceRange(4, 5));
  }

  test_endLength() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction =
        testUnit.declarations[0] as FunctionDeclaration;
    SimpleIdentifier mainName = mainFunction.name;
    expect(range.endLength(mainName, 3), SourceRange(4, 3));
  }

  test_endStart() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction =
        testUnit.declarations[0] as FunctionDeclaration;
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(range.endStart(mainName, mainBody), SourceRange(4, 3));
  }

  test_error() {
    AnalysisError error =
        AnalysisError(null, 10, 5, ParserErrorCode.CONST_CLASS, []);
    expect(range.error(error), SourceRange(10, 5));
  }

  test_node() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction =
        testUnit.declarations[0] as FunctionDeclaration;
    SimpleIdentifier mainName = mainFunction.name;
    expect(range.node(mainName), SourceRange(0, 4));
  }

  test_nodes() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction =
        testUnit.declarations[0] as FunctionDeclaration;
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(range.nodes([mainName, mainBody]), SourceRange(1, 9));
  }

  test_nodes_empty() async {
    await resolveTestUnit('main() {}');
    expect(range.nodes([]), SourceRange(0, 0));
  }

  test_offsetBy() {
    expect(range.offsetBy(SourceRange(7, 3), 2), SourceRange(9, 3));
  }

  test_startEnd_nodeNode() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction =
        testUnit.declarations[0] as FunctionDeclaration;
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(range.startEnd(mainName, mainBody), SourceRange(1, 9));
  }

  test_startLength_node() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction =
        testUnit.declarations[0] as FunctionDeclaration;
    SimpleIdentifier mainName = mainFunction.name;
    expect(range.startLength(mainName, 10), SourceRange(1, 10));
  }

  test_startOffsetEndOffset() {
    expect(range.startOffsetEndOffset(6, 11), SourceRange(6, 5));
  }

  test_startStart_nodeNode() async {
    await resolveTestUnit('main() {}');
    FunctionDeclaration mainFunction =
        testUnit.declarations[0] as FunctionDeclaration;
    SimpleIdentifier mainName = mainFunction.name;
    FunctionBody mainBody = mainFunction.functionExpression.body;
    expect(range.startStart(mainName, mainBody), SourceRange(0, 7));
  }

  test_token() async {
    await resolveTestUnit(' main() {}');
    FunctionDeclaration mainFunction =
        testUnit.declarations[0] as FunctionDeclaration;
    SimpleIdentifier mainName = mainFunction.name;
    expect(range.token(mainName.beginToken), SourceRange(1, 4));
  }
}
