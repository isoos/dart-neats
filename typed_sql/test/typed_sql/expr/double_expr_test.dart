// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:typed_sql/typed_sql.dart';

import '../testrunner.dart';

abstract final class TestDatabase extends Schema {}

final _cases = [
  // Test for .equals
  (
    name: '0.0.equals(0.0)',
    expr: literal(0.0).equals(literal(0.0)),
    expected: true,
  ),
  (
    name: '1.2.equals(1.5)',
    expr: literal(1.2).equals(literal(1.5)),
    expected: false,
  ),
  (
    name: '1.5.equals(1.2)',
    expr: literal(1.5).equals(literal(1.2)),
    expected: false,
  ),
  (
    name: '1.5.equals(1.5)',
    expr: literal(1.5).equals(literal(1.5)),
    expected: true,
  ),
  (
    name: '-1.5.equals(-1.5)',
    expr: literal(-1.5).equals(literal(-1.5)),
    expected: true,
  ),
  (
    name: '3.14.equals(3.14)',
    expr: literal(3.14).equals(literal(3.14)),
    expected: true,
  ),

  // Test for .equalsLiteral
  (
    name: '0.0.equalsLiteral(0.0)',
    expr: literal(0.0).equalsLiteral(0.0),
    expected: true,
  ),
  (
    name: '1.2.equalsLiteral(1.5)',
    expr: literal(1.2).equalsLiteral(1.5),
    expected: false,
  ),
  (
    name: '1.5.equalsLiteral(1.2)',
    expr: literal(1.5).equalsLiteral(1.2),
    expected: false,
  ),
  (
    name: '1.5.equalsLiteral(1.5)',
    expr: literal(1.5).equalsLiteral(1.5),
    expected: true,
  ),
  (
    name: '-1.5.equalsLiteral(-1.5)',
    expr: literal(-1.5).equalsLiteral(-1.5),
    expected: true,
  ),
  (
    name: '3.14.equalsLiteral(3.14)',
    expr: literal(3.14).equalsLiteral(3.14),
    expected: true,
  ),

  // Test for .notEquals
  (
    name: '0.0.notEquals(0.0)',
    expr: literal(0.0).notEquals(literal(0.0)),
    expected: false,
  ),
  (
    name: '1.2.notEquals(1.5)',
    expr: literal(1.2).notEquals(literal(1.5)),
    expected: true,
  ),
  (
    name: '1.5.notEquals(1.2)',
    expr: literal(1.5).notEquals(literal(1.2)),
    expected: true,
  ),
  (
    name: '1.5.notEquals(1.5)',
    expr: literal(1.5).notEquals(literal(1.5)),
    expected: false,
  ),
  (
    name: '-1.5.notEquals(-1.5)',
    expr: literal(-1.5).notEquals(literal(-1.5)),
    expected: false,
  ),
  (
    name: '3.14.notEquals(3.14)',
    expr: literal(3.14).notEquals(literal(3.14)),
    expected: false,
  ),

  // Test for .notEqualsLiteral
  (
    name: '0.0.notEqualsLiteral(0.0)',
    expr: literal(0.0).notEqualsLiteral(0.0),
    expected: false,
  ),
  (
    name: '1.2.notEqualsLiteral(1.5)',
    expr: literal(1.2).notEqualsLiteral(1.5),
    expected: true,
  ),
  (
    name: '1.5.notEqualsLiteral(1.2)',
    expr: literal(1.5).notEqualsLiteral(1.2),
    expected: true,
  ),
  (
    name: '1.5.notEqualsLiteral(1.5)',
    expr: literal(1.5).notEqualsLiteral(1.5),
    expected: false,
  ),
  (
    name: '-1.5.notEqualsLiteral(-1.5)',
    expr: literal(-1.5).notEqualsLiteral(-1.5),
    expected: false,
  ),
  (
    name: '3.14.notEqualsLiteral(3.14)',
    expr: literal(3.14).notEqualsLiteral(3.14),
    expected: false,
  ),

  // Test for .lessThan

  // Tests for .lessThanLiteral

  // Test for <

  // Test for .lessThanOrEqual

  // Tests for .lessThanOrEqualLiteral

  // Test for <=

  // Test for .greaterThan

  // Tests for .greaterThanLiteral

  // Test for >

  // Test for .greaterThanOrEqual

  // Tests for .greaterThanOrEqualLiteral

  // Test for >=
];

final _closeCases = [
  // Test for +
  (
    name: '0.0 + 0.0',
    expr: literal(0.0) + literal(0.0),
    expected: 0.0,
  ),
  (
    name: '0.0 + 1.0',
    expr: literal(0.0) + literal(1.0),
    expected: 1.0,
  ),
  (
    name: '1.0 + 0.0',
    expr: literal(1.0) + literal(0.0),
    expected: 1.0,
  ),
  (
    name: '1.5 + 1.2',
    expr: literal(1.5) + literal(1.2),
    expected: 2.7,
  ),
  (
    name: '-1.0 + -1.0',
    expr: literal(-1.0) + literal(-1.0),
    expected: -2.0,
  ),
  (
    name: '3.14 + 3.14',
    expr: literal(3.14) + literal(3.14),
    expected: 6.28,
  ),

  // Test for -
  (
    name: '0.0 - 0.0',
    expr: literal(0.0) - literal(0.0),
    expected: 0.0,
  ),
  (
    name: '0.0 - 1.0',
    expr: literal(0.0) - literal(1.0),
    expected: -1.0,
  ),
  (
    name: '1.0 - 0.0',
    expr: literal(1.0) - literal(0.0),
    expected: 1.0,
  ),
  (
    name: '1.5 - 1.2',
    expr: literal(1.5) - literal(1.2),
    expected: 0.3,
  ),
  (
    name: '-1.0 - -1.0',
    expr: literal(-1.0) - literal(-1.0),
    expected: 0.0,
  ),
  (
    name: '3.14 - 3.14',
    expr: literal(3.14) - literal(3.14),
    expected: 0.0,
  ),

  // Test for *
  (
    name: '0.0 * 0.0',
    expr: literal(0.0) * literal(0.0),
    expected: 0.0,
  ),
  (
    name: '0.0 * 1.0',
    expr: literal(0.0) * literal(1.0),
    expected: 0.0,
  ),
  (
    name: '1.0 * 0.0',
    expr: literal(1.0) * literal(0.0),
    expected: 0.0,
  ),
  (
    name: '1.5 * 1.2',
    expr: literal(1.5) * literal(1.2),
    expected: 1.8,
  ),
  (
    name: '-1.0 * -1.0',
    expr: literal(-1.0) * literal(-1.0),
    expected: 1.0,
  ),
  (
    name: '3.14 * 3.14',
    expr: literal(3.14) * literal(3.14),
    expected: 9.8596,
  ),

  // Test for /
  (
    name: '0.0 / 1.0',
    expr: literal(0.0) / literal(1.0),
    expected: 0.0,
  ),
  (
    name: '1.0 / 1.0',
    expr: literal(1.0) / literal(1.0),
    expected: 1.0,
  ),
  (
    name: '-1.0 / -1.0',
    expr: literal(-1.0) / literal(-1.0),
    expected: 1.0,
  ),
  (
    name: '3.14 / 3.14',
    expr: literal(3.14) / literal(3.14),
    expected: 1.0,
  ),
  (
    name: '3.14 / 2.0',
    expr: literal(3.14) / literal(2.0),
    expected: 1.57,
  ),
  (
    name: '3.15 / 2.0',
    expr: literal(3.15) / literal(2.0),
    expected: 1.575,
  ),

  // Tests for .add
  (
    name: '0.0.add(0.0)',
    expr: literal(0.0).add(literal(0.0)),
    expected: 0.0,
  ),
  (
    name: '0.0.add(1.0)',
    expr: literal(0.0).add(literal(1.0)),
    expected: 1.0,
  ),
  (
    name: '1.0.add(0.0)',
    expr: literal(1.0).add(literal(0.0)),
    expected: 1.0,
  ),
  (
    name: '1.5.add(1.2)',
    expr: literal(1.5).add(literal(1.2)),
    expected: 2.7,
  ),
  (
    name: '-1.0.add(-1.0)',
    expr: literal(-1.0).add(literal(-1.0)),
    expected: -2.0,
  ),
  (
    name: '3.14.add(3.14)',
    expr: literal(3.14).add(literal(3.14)),
    expected: 6.28,
  ),

  // Tests for .addLiteral
  (
    name: '0.0.addLiteral(0.0)',
    expr: literal(0.0).addLiteral(0.0),
    expected: 0.0,
  ),
  (
    name: '0.0.addLiteral(1.0)',
    expr: literal(0.0).addLiteral(1.0),
    expected: 1.0,
  ),
  (
    name: '1.0.addLiteral(0.0)',
    expr: literal(1.0).addLiteral(0.0),
    expected: 1.0,
  ),
  (
    name: '1.5.addLiteral(1.2)',
    expr: literal(1.5).addLiteral(1.2),
    expected: 2.7,
  ),
  (
    name: '-1.0.addLiteral(-1.0)',
    expr: literal(-1.0).addLiteral(-1.0),
    expected: -2.0,
  ),
  (
    name: '3.14.addLiteral(3.14)',
    expr: literal(3.14).addLiteral(3.14),
    expected: 6.28,
  ),

  // Tests for .subtract
  (
    name: '0.0.subtract(0.0)',
    expr: literal(0.0).subtract(literal(0.0)),
    expected: 0.0,
  ),
  (
    name: '0.0.subtract(1.0)',
    expr: literal(0.0).subtract(literal(1.0)),
    expected: -1.0,
  ),
  (
    name: '1.0.subtract(0.0)',
    expr: literal(1.0).subtract(literal(0.0)),
    expected: 1.0,
  ),
  (
    name: '1.5.subtract(1.2)',
    expr: literal(1.5).subtract(literal(1.2)),
    expected: 0.3,
  ),
  (
    name: '-1.0.subtract(-1.0)',
    expr: literal(-1.0).subtract(literal(-1.0)),
    expected: 0.0,
  ),
  (
    name: '3.14.subtract(3.14)',
    expr: literal(3.14).subtract(literal(3.14)),
    expected: 0.0,
  ),

  // Tests for .subtractLiteral
  (
    name: '0.0.subtractLiteral(0.0)',
    expr: literal(0.0).subtractLiteral(0.0),
    expected: 0.0,
  ),
  (
    name: '0.0.subtractLiteral(1.0)',
    expr: literal(0.0).subtractLiteral(1.0),
    expected: -1.0,
  ),
  (
    name: '1.0.subtractLiteral(0.0)',
    expr: literal(1.0).subtractLiteral(0.0),
    expected: 1.0,
  ),
  (
    name: '1.5.subtractLiteral(1.2)',
    expr: literal(1.5).subtractLiteral(1.2),
    expected: 0.3,
  ),
  (
    name: '-1.0.subtractLiteral(-1.0)',
    expr: literal(-1.0).subtractLiteral(-1.0),
    expected: 0.0,
  ),
  (
    name: '3.14.subtractLiteral(3.14)',
    expr: literal(3.14).subtractLiteral(3.14),
    expected: 0.0,
  ),

  // Tests for .multiply
  (
    name: '0.0.multiply(0.0)',
    expr: literal(0.0).multiply(literal(0.0)),
    expected: 0.0,
  ),
  (
    name: '0.0.multiply(1.0)',
    expr: literal(0.0).multiply(literal(1.0)),
    expected: 0.0,
  ),
  (
    name: '1.0.multiply(0.0)',
    expr: literal(1.0).multiply(literal(0.0)),
    expected: 0.0,
  ),
  (
    name: '1.5.multiply(1.2)',
    expr: literal(1.5).multiply(literal(1.2)),
    expected: 1.8,
  ),
  (
    name: '-1.0.multiply(-1.0)',
    expr: literal(-1.0).multiply(literal(-1.0)),
    expected: 1.0,
  ),
  (
    name: '3.14.multiply(3.14)',
    expr: literal(3.14).multiply(literal(3.14)),
    expected: 9.8596,
  ),

  // Tests for .multiplyLiteral
  (
    name: '0.0.multiplyLiteral(0.0)',
    expr: literal(0.0).multiplyLiteral(0.0),
    expected: 0.0,
  ),
  (
    name: '0.0.multiplyLiteral(1.0)',
    expr: literal(0.0).multiplyLiteral(1.0),
    expected: 0.0,
  ),
  (
    name: '1.0.multiplyLiteral(0.0)',
    expr: literal(1.0).multiplyLiteral(0.0),
    expected: 0.0,
  ),
  (
    name: '1.5.multiplyLiteral(1.2)',
    expr: literal(1.5).multiplyLiteral(1.2),
    expected: 1.8,
  ),
  (
    name: '-1.0.multiplyLiteral(-1.0)',
    expr: literal(-1.0).multiplyLiteral(-1.0),
    expected: 1.0,
  ),
  (
    name: '3.14.multiplyLiteral(3.14)',
    expr: literal(3.14).multiplyLiteral(3.14),
    expected: 9.8596,
  ),

  // Tests for .divide
  (
    name: '0.0.divide(1.0)',
    expr: literal(0.0).divide(literal(1.0)),
    expected: 0.0,
  ),
  (
    name: '1.0.divide(1.0)',
    expr: literal(1.0).divide(literal(1.0)),
    expected: 1.0,
  ),
  (
    name: '-1.0.divide(-1.0)',
    expr: literal(-1.0).divide(literal(-1.0)),
    expected: 1.0,
  ),
  (
    name: '3.14.divide(3.14)',
    expr: literal(3.14).divide(literal(3.14)),
    expected: 1.0,
  ),
  (
    name: '3.14.divide(2.0)',
    expr: literal(3.14).divide(literal(2.0)),
    expected: 1.57,
  ),
  (
    name: '3.15.divide(2.0)',
    expr: literal(3.15).divide(literal(2.0)),
    expected: 1.575,
  ),

  // Tests for .divideLiteral
  (
    name: '0.0.divideLiteral(1.0)',
    expr: literal(0.0).divideLiteral(1.0),
    expected: 0.0,
  ),
  (
    name: '1.0.divideLiteral(1.0)',
    expr: literal(1.0).divideLiteral(1.0),
    expected: 1.0,
  ),
  (
    name: '-1.0.divideLiteral(-1.0)',
    expr: literal(-1.0).divideLiteral(-1.0),
    expected: 1.0,
  ),
  (
    name: '3.14.divideLiteral(3.14)',
    expr: literal(3.14).divideLiteral(3.14),
    expected: 1.0,
  ),
  (
    name: '3.14.divideLiteral(2.0)',
    expr: literal(3.14).divideLiteral(2.0),
    expected: 1.57,
  ),
  (
    name: '3.15.divideLiteral(2.0)',
    expr: literal(3.15).divideLiteral(2.0),
    expected: 1.575,
  ),
];

void main() {
  final r = TestRunner<TestDatabase>();

  for (final c in _cases) {
    r.addTest(c.name, (db) async {
      final result = await db.select(
        (c.expr,),
      ).fetch();
      check(result).isNotNull().equals(c.expected);
    });
  }

  for (final c in _closeCases) {
    r.addTest(c.name, (db) async {
      final result = await db.select(
        (c.expr,),
      ).fetch();
      check(result).isNotNull().isCloseTo(c.expected, 0.00000000000001);
    });
  }

  r.run();
}
