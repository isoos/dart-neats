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

part of 'typed_sql.dart';

sealed class Expr<T extends Object?> {
  factory Expr(T value) => literal(value);

  const Expr._();

  int get _columns => 1;
  T _decode(RowReader row) {
    return switch (this) {
      Expr<bool>() => row.readBool() as T,
      Expr<DateTime>() => row.readDateTime() as T,
      Expr<double>() => row.readDouble() as T,
      Expr<int>() => row.readInt() as T,
      Expr<String>() => row.readString() as T,
      Expr<bool?>() => row.readBool() as T,
      Expr<DateTime?>() => row.readDateTime() as T,
      Expr<double?>() => row.readDouble() as T,
      Expr<int?>() => row.readInt() as T,
      Expr<String?>() => row.readString() as T,
      _ => throw AssertionError('Expr<T> must be bool, DateTime')
    };
  }

  Expr<T> _standin(int index, Object handle) => FieldExpression(index, handle);

  static const null$ = Literal.null$;
  static const true$ = Literal.true$;
  static const false$ = Literal.false$;

  Expr<R> _field<R>(int index) =>
      // This should never happen!
      throw AssertionError('Only Expr<Model> can have fields');

  static Literal<T> literal<T extends Object?>(T value) => Literal(value);
}

Literal<T> literal<T extends Object?>(T value) => Literal(value);

/// An expression that consists of multiple values.
///
/// Expression that forms a tuple or represents a model.
sealed class MultiValueExpression<T> extends Expr<T> {
  /// Return list of subexpressions for the underlying values.
  List<Expr<Object?>> explode();

  MultiValueExpression._() : super._();
}

extension<T extends Model> on Query<(Expr<T>,)> {
  Table<T> get table => switch (_expressions.$1) {
        final ModelFieldExpression<T> e => e.table,
        _ => throw AssertionError('Expr<Model> must be ModelExpression'),
      };
}

sealed class ModelExpression<T extends Model> extends MultiValueExpression<T> {
  // TODO: These should be private!
  final Table<T> table;

  @override
  Expr<T> _standin(int index, Object handle) =>
      ModelFieldExpression(index, table, handle);

  @override
  int get _columns => table._tableClause.columns.length;

  @override
  T _decode(RowReader row) => table._deserialize(row);

  @override
  List<Expr<Object?>> explode() => List.generate(_columns, _field);

  ModelExpression._(this.table) : super._();
}

final class ModelFieldExpression<T extends Model> extends ModelExpression<T> {
  // TODO: These should be private!
  final int index;
  final Object handle;

  @override
  Expr<T> _standin(int index, Object handle) =>
      ModelFieldExpression(index, table, handle);

  @override
  int get _columns => table._tableClause.columns.length;

  @override
  T _decode(RowReader row) => table._deserialize(row);

  Expr<R> _field<R>(int index) {
    if (index < 0 || index >= table._tableClause.columns.length) {
      throw ArgumentError.value(
        index,
        'index',
        'Table "${table._tableClause.name}" does not have a field '
            'at index $index',
      );
    }
    return FieldExpression(this.index + index, handle);
  }

  @override
  List<Expr<Object?>> explode() => List.generate(_columns, _field);

  ModelFieldExpression(this.index, super.table, this.handle) : super._();
}

final class ModelSubQueryExpression<T extends Model>
    extends ModelExpression<T> {
  final QueryClause query;

  Expr<R> _field<R>(int index) {
    if (index < 0 || index >= table._tableClause.columns.length) {
      throw ArgumentError.value(
        index,
        'index',
        'Table "${table._tableClause.name}" does not have a field '
            'at index $index',
      );
    }

    final handle = Object();
    return SubQueryExpression._(SelectFromClause._(
      query,
      handle,
      [FieldExpression(index, handle)],
    ));
  }

  ModelSubQueryExpression._(this.query, super.table) : super._();
}

final class FieldExpression<T> extends Expr<T> {
  // TODO: These should be private!
  final int index;
  final Object handle;

  FieldExpression(this.index, this.handle) : super._();
}

final class SubQueryExpression<T> extends Expr<T> {
  final QueryClause query;

  SubQueryExpression._(this.query) : super._();
}

final class ExistsExpression extends Expr<bool> {
  final QueryClause query;
  ExistsExpression._(this.query) : super._();
}

final class SumExpression<T extends num> extends Expr<T> {
  final Expr<T> value;
  SumExpression._(this.value) : super._();
}

final class AvgExpression extends Expr<double> {
  final Expr<num> value;
  AvgExpression._(this.value) : super._();
}

// TODO: Consider if T extends Comparable makes sense!
final class MinExpression<T extends Comparable> extends Expr<T> {
  final Expr<T> value;
  MinExpression._(this.value) : super._();
}

final class MaxExpression<T extends Comparable> extends Expr<T> {
  final Expr<T> value;
  MaxExpression._(this.value) : super._();
}

final class CountExpression extends Expr<int> {
  final Expr<Object?> expression;
  final bool distinct;
  CountExpression._(this.expression, this.distinct) : super._();
}

final class CountAllExpression extends Expr<int> {
  CountAllExpression._() : super._();
}

final class Literal<T> extends Expr<T> {
  final T value;
  // TODO: Consider supporting a Constant expression subclass, currently we
  //       always encode literals as ? and attach them as parameters.
  //       This is fine, but if we ever use this query builders to created
  //       prepared statements that are executed more than once, then it matters
  //       whether a literal is encoded as value or constant
  //       If we do this, we might have rename Literal to Value!

  static const null$ = Literal._(null);
  static const true$ = Literal._(true);
  static const false$ = Literal._(false);

  const Literal._(this.value) : super._();

  factory Literal(T value) {
    if (value == null) {
      return null$ as Literal<T>;
    }
    if (value is bool) {
      if (value) {
        return true$ as Literal<T>;
      } else {
        return false$ as Literal<T>;
      }
    }
    if (value is! String &&
        value is! int &&
        value is! double &&
        // TODO: Isn't null allowed?
        value is! DateTime) {
      throw ArgumentError.value(
        value,
        'value',
        'Only String, int, double, bool, null, and DateTime '
            'literals are allowed',
      );
    }
    return Literal._(value);
  }
}

sealed class BinaryOperationExpression<T, R> extends Expr<R> {
  final Expr<T> left;
  final Expr<T> right;
  BinaryOperationExpression(this.left, this.right) : super._();
}

final class ExpressionBoolNot extends Expr<bool> {
  final Expr<bool> value;
  ExpressionBoolNot(this.value) : super._();
}

final class ExpressionBoolAnd extends BinaryOperationExpression<bool, bool> {
  ExpressionBoolAnd(super.left, super.right);
}

final class ExpressionBoolOr extends BinaryOperationExpression<bool, bool> {
  ExpressionBoolOr(super.left, super.right);
}

final class ExpressionStringEquals
    extends BinaryOperationExpression<String, bool> {
  ExpressionStringEquals(super.left, super.right);
}

final class ExpressionStringLessThan
    extends BinaryOperationExpression<String, bool> {
  ExpressionStringLessThan(super.left, super.right);
}

final class ExpressionStringLessThanOrEqual
    extends BinaryOperationExpression<String, bool> {
  ExpressionStringLessThanOrEqual(super.left, super.right);
}

final class ExpressionStringGreaterThan
    extends BinaryOperationExpression<String, bool> {
  ExpressionStringGreaterThan(super.left, super.right);
}

final class ExpressionStringGreaterThanOrEqual
    extends BinaryOperationExpression<String, bool> {
  ExpressionStringGreaterThanOrEqual(super.left, super.right);
}

final class ExpressionStringIsEmpty extends Expr<bool> {
  final Expr<String> value;
  ExpressionStringIsEmpty(this.value) : super._();
}

final class ExpressionStringLength extends Expr<int> {
  final Expr<String> value;
  ExpressionStringLength(this.value) : super._();
}

final class ExpressionStringStartsWith extends Expr<bool> {
  final Expr<String> value;
  final Expr<String> prefix;
  ExpressionStringStartsWith(this.value, this.prefix) : super._();
}

final class ExpressionStringEndsWith extends Expr<bool> {
  final Expr<String> value;
  final Expr<String> suffix;
  ExpressionStringEndsWith(this.value, this.suffix) : super._();
}

final class ExpressionStringLike extends Expr<bool> {
  final Expr<String> value;
  final String pattern;
  ExpressionStringLike(this.value, this.pattern) : super._();
}

final class ExpressionStringContains extends Expr<bool> {
  final Expr<String> value;
  final Expr<String> needle;
  ExpressionStringContains(this.value, this.needle) : super._();
}

final class ExpressionStringToUpperCase extends Expr<String> {
  final Expr<String> value;
  ExpressionStringToUpperCase(this.value) : super._();
}

final class ExpressionStringToLowerCase extends Expr<String> {
  final Expr<String> value;
  ExpressionStringToLowerCase(this.value) : super._();
}

final class ExpressionNumEquals<T extends num>
    extends BinaryOperationExpression<T, bool> {
  ExpressionNumEquals(super.left, super.right);
}

final class ExpressionNumAdd<T extends num>
    extends BinaryOperationExpression<T, T> {
  ExpressionNumAdd(super.left, super.right);
}

final class ExpressionNumSubtract<T extends num>
    extends BinaryOperationExpression<T, T> {
  ExpressionNumSubtract(super.left, super.right);
}

final class ExpressionNumMultiply<T extends num>
    extends BinaryOperationExpression<T, T> {
  ExpressionNumMultiply(super.left, super.right);
}

final class ExpressionNumDivide<T extends num>
    extends BinaryOperationExpression<T, T> {
  ExpressionNumDivide(super.left, super.right);
}

final class ExpressionNumLessThan<T extends num>
    extends BinaryOperationExpression<T, bool> {
  ExpressionNumLessThan(super.left, super.right);
}

final class ExpressionNumLessThanOrEqual<T extends num>
    extends BinaryOperationExpression<T, bool> {
  ExpressionNumLessThanOrEqual(super.left, super.right);
}

final class ExpressionNumGreaterThan<T extends num>
    extends BinaryOperationExpression<T, bool> {
  ExpressionNumGreaterThan(super.left, super.right);
}

final class ExpressionNumGreaterThanOrEqual<T extends num>
    extends BinaryOperationExpression<T, bool> {
  ExpressionNumGreaterThanOrEqual(super.left, super.right);
}

final class ExpressionDateTimeEquals
    extends BinaryOperationExpression<DateTime, bool> {
  ExpressionDateTimeEquals(super.left, super.right);
}

final class ExpressionDateTimeLessThan
    extends BinaryOperationExpression<DateTime, bool> {
  ExpressionDateTimeLessThan(super.left, super.right);
}

final class ExpressionDateTimeLessThanOrEqual
    extends BinaryOperationExpression<DateTime, bool> {
  ExpressionDateTimeLessThanOrEqual(super.left, super.right);
}

final class ExpressionDateTimeGreaterThan
    extends BinaryOperationExpression<DateTime, bool> {
  ExpressionDateTimeGreaterThan(super.left, super.right);
}

final class ExpressionDateTimeGreaterThanOrEqual
    extends BinaryOperationExpression<DateTime, bool> {
  ExpressionDateTimeGreaterThanOrEqual(super.left, super.right);
}

extension ExpressionBool on Expr<bool> {
  Expr<bool> not() => ExpressionBoolNot(this);
  Expr<bool> operator ~() => ExpressionBoolNot(this);

  Expr<bool> and(Expr<bool> other) {
    if (other == Literal.true$) {
      return this;
    }
    if (other == Literal.false$) {
      return Literal.false$;
    }
    if (this == Literal.true$) {
      return other;
    }
    return ExpressionBoolAnd(this, other);
  }

  Expr<bool> operator &(Expr<bool> other) => and(other);

  Expr<bool> or(Expr<bool> other) => ExpressionBoolOr(this, other);
  Expr<bool> operator |(Expr<bool> other) => ExpressionBoolOr(this, other);
}

extension ExpressionString on Expr<String> {
  Expr<bool> equals(Expr<String> value) => ExpressionStringEquals(this, value);
  Expr<bool> equalsLiteral(String value) => equals(literal(value));

  Expr<bool> notEquals(Expr<String> value) => equals(value).not();
  Expr<bool> notEqualsLiteral(String value) => notEquals(literal(value));

  Expr<bool> get isEmpty => ExpressionStringIsEmpty(this);
  Expr<bool> get isNotEmpty => isEmpty.not();

  Expr<int> get length => ExpressionStringLength(this);

  Expr<bool> startsWith(Expr<String> value) =>
      ExpressionStringStartsWith(this, value);
  Expr<bool> startsWithLiteral(String value) =>
      ExpressionStringStartsWith(this, literal(value));

  Expr<bool> endsWith(Expr<String> value) =>
      ExpressionStringEndsWith(this, value);
  Expr<bool> endsWithLiteral(String value) =>
      ExpressionStringEndsWith(this, literal(value));

  /// Matches pattern where `%` is one or more characters, and
  /// `_` is one character.
  Expr<bool> like(String pattern) => ExpressionStringLike(this, pattern);

  Expr<bool> contains(Expr<String> substring) =>
      ExpressionStringContains(this, substring);

  Expr<bool> containsLiteral(String substring) =>
      ExpressionStringContains(this, literal(substring));

  Expr<String> toLowerCase() => ExpressionStringToLowerCase(this);

  Expr<String> toUpperCase() => ExpressionStringToUpperCase(this);

  Expr<bool> operator >=(Expr<String> other) =>
      ExpressionStringGreaterThanOrEqual(this, other);
  Expr<bool> operator <=(Expr<String> other) =>
      ExpressionStringLessThanOrEqual(this, other);
  Expr<bool> operator >(Expr<String> other) =>
      ExpressionStringGreaterThan(this, other);
  Expr<bool> operator <(Expr<String> other) =>
      ExpressionStringLessThan(this, other);

  Expr<bool> lessThan(Expr<String> other) =>
      ExpressionStringLessThan(this, other);
  Expr<bool> lessThanOrEqual(Expr<String> other) =>
      ExpressionStringLessThanOrEqual(this, other);
  Expr<bool> greaterThan(Expr<String> other) =>
      ExpressionStringGreaterThan(this, other);
  Expr<bool> greaterThanOrEqual(Expr<String> other) =>
      ExpressionStringGreaterThanOrEqual(this, other);

  Expr<bool> lessThanLiteral(String other) => lessThan(literal(other));
  Expr<bool> lessThanOrEqualLiteral(String other) =>
      lessThanOrEqual(literal(other));
  Expr<bool> greaterThanLiteral(String other) => greaterThan(literal(other));
  Expr<bool> greaterThanOrEqualLiteral(String other) =>
      greaterThanOrEqual(literal(other));
}

extension ExpressionNum<T extends num> on Expr<T> {
  Expr<bool> equals(Expr<T> value) => ExpressionNumEquals(this, value);
  Expr<bool> equalsLiteral(num value) =>
      ExpressionNumEquals(this, literal(value));

  Expr<bool> notEquals(Expr<T> value) => equals(value).not();
  Expr<bool> notEqualsLiteral(T value) => notEquals(literal(value));

  Expr<T> operator +(Expr<T> other) => ExpressionNumAdd(this, other);
  Expr<T> operator -(Expr<T> other) => ExpressionNumSubtract(this, other);
  Expr<T> operator *(Expr<T> other) => ExpressionNumMultiply(this, other);
  Expr<T> operator /(Expr<T> other) => ExpressionNumDivide(this, other);

  Expr<T> add(Expr<T> other) => ExpressionNumAdd(this, other);
  Expr<T> subtract(Expr<T> other) => ExpressionNumSubtract(this, other);
  Expr<T> multiply(Expr<T> other) => ExpressionNumMultiply(this, other);
  Expr<T> divide(Expr<T> other) => ExpressionNumDivide(this, other);

  Expr<T> addLiteral(T other) => ExpressionNumAdd(this, literal(other));
  Expr<T> subtractLiteral(T other) =>
      ExpressionNumSubtract(this, literal(other));
  Expr<T> multiplyLiteral(T other) =>
      ExpressionNumMultiply(this, literal(other));
  Expr<T> divideLiteral(T other) => ExpressionNumDivide(this, literal(other));

  Expr<bool> operator >=(Expr<T> other) =>
      ExpressionNumGreaterThanOrEqual(this, other);
  Expr<bool> operator <=(Expr<T> other) =>
      ExpressionNumLessThanOrEqual(this, other);
  Expr<bool> operator >(Expr<T> other) => ExpressionNumGreaterThan(this, other);
  Expr<bool> operator <(Expr<T> other) => ExpressionNumLessThan(this, other);

  Expr<bool> lessThan(Expr<T> other) => ExpressionNumLessThan(this, other);
  Expr<bool> lessThanOrEqual(Expr<T> other) =>
      ExpressionNumLessThanOrEqual(this, other);
  Expr<bool> greaterThan(Expr<T> other) =>
      ExpressionNumGreaterThan(this, other);
  Expr<bool> greaterThanOrEqual(Expr<T> other) =>
      ExpressionNumGreaterThanOrEqual(this, other);

  Expr<bool> lessThanLiteral(T other) => lessThan(literal(other));
  Expr<bool> lessThanOrEqualLiteral(T other) => lessThanOrEqual(literal(other));
  Expr<bool> greaterThanLiteral(T other) => greaterThan(literal(other));
  Expr<bool> greaterThanOrEqualLiteral(T other) =>
      greaterThanOrEqual(literal(other));

  //... do other operators...
}

extension ExpressionDateTime on Expr<DateTime> {
  Expr<bool> equals(Expr<DateTime> value) =>
      ExpressionDateTimeEquals(this, value);
  Expr<bool> equalsLiteral(DateTime value) =>
      ExpressionDateTimeEquals(this, literal(value));

  Expr<bool> notEquals(Expr<DateTime> value) => equals(value).not();
  Expr<bool> notEqualsLiteral(DateTime value) => notEquals(literal(value));

  // TODO: Decide if we want to support storing a Duration
  // Expression<bool> difference(Expression<DateTime> value) =>

  Expr<bool> operator >=(Expr<DateTime> other) =>
      ExpressionDateTimeGreaterThanOrEqual(this, other);
  Expr<bool> operator <=(Expr<DateTime> other) =>
      ExpressionDateTimeLessThanOrEqual(this, other);
  Expr<bool> operator >(Expr<DateTime> other) =>
      ExpressionDateTimeGreaterThan(this, other);
  Expr<bool> operator <(Expr<DateTime> other) =>
      ExpressionDateTimeLessThan(this, other);

  Expr<bool> isBefore(Expr<DateTime> value) => this < value;
  Expr<bool> isBeforeLiteral(DateTime value) => isBefore(literal(value));

  Expr<bool> isAfter(Expr<DateTime> value) => this > value;
  Expr<bool> isAfterLiteral(DateTime value) => isAfter(literal(value));

  // TODO: More features... maybe there is a duration in SQL?
}
