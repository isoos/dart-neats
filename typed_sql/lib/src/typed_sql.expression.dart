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

  int get _columns;
  T _decode(RowReader row);

  Expr<T> _standin(int index, Object handle);
  Expr<R> _field<R>(int index, R Function(RowReader) readValue);

  Iterable<Expr<Object?>> _explode();

  static const null$ = Literal.null$;
  static const true$ = Literal.true$;
  static const false$ = Literal.false$;

  static Literal<T> literal<T extends Object?>(T value) => Literal(value);
}

sealed class SingleValueExpr<T extends Object?> extends Expr<T> {
  const SingleValueExpr._() : super._();

  @override
  Iterable<Expr<T>> _explode() sync* {
    yield this;
  }

  @override
  Expr<T> _standin(int index, Object handle) =>
      FieldExpression(index, handle, _decode);

  @override
  Expr<R> _field<R>(int index, R Function(RowReader) readValue) =>
      // This should never happen!
      throw AssertionError('Only Expr<Model> can have fields');

  @override
  int get _columns => 1;
}

Literal<T> literal<T extends Object?>(T value) => Literal(value);

final class ModelExpression<T extends Model> extends Expr<T> {
  final TableDefinition<T> _table;
  final int _index;
  final Object _handle;

  @override
  Expr<T> _standin(int index, Object handle) =>
      ModelExpression(index, _table, handle);

  @override
  int get _columns => _table.columns.length;

  @override
  T _decode(RowReader row) => _table.readModel(row);

  Expr<R> _field<R>(int index, R Function(RowReader) readValue) {
    if (index < 0 || index >= _table.columns.length) {
      throw ArgumentError.value(
        index,
        'index',
        'Table "${_table.tableName}" does not have a field '
            'at index $index',
      );
    }
    return FieldExpression(this._index + index, _handle, readValue);
  }

  @override
  Iterable<Expr<Object?>> _explode() => Iterable.generate(
      _columns,
      (index) => _field<Never>(
            index,
            (r) => throw AssertionError(
              'Exploded Expr<T> may not be decoded, '
              'Expr<T> from QueryClause may not be reused!',
            ),
          )).expand((e) => e._explode());

  ModelExpression(this._index, this._table, this._handle) : super._();
}

final class FieldExpression<T> extends SingleValueExpr<T> {
  final int _index;
  final Object _handle;
  final T Function(RowReader) _readValue;

  @override
  T _decode(RowReader row) => _readValue(row);

  FieldExpression(this._index, this._handle, this._readValue) : super._();
}

final class SubQueryExpression<T> extends Expr<T> {
  final QueryClause query;
  final Expr<T> _value;

  SubQueryExpression._(this.query, this._value) : super._();

  @override
  int get _columns => _value._columns;

  @override
  T _decode(RowReader row) => _value._decode(row);

  @override
  Iterable<Expr<Object?>> _explode() {
    if (_columns == 1) {
      return [this];
    }
    return Iterable.generate(
        _columns,
        (index) => _field<Never>(
              index,
              (r) => throw AssertionError(
                'Exploded Expr<T> may not be decoded, '
                'Expr<T> from QueryClause may not be reused!',
              ),
            )).expand((e) => e._explode());
  }

  @override
  Expr<R> _field<R>(int index, R Function(RowReader) readValue) {
    final handle = Object();
    return SubQueryExpression._(
      SelectFromClause._(
        query,
        handle,
        [FieldExpression(index, handle, readValue)],
      ),
      _value._field<R>(index, readValue),
    );
  }

  @override
  Expr<T> _standin(int index, Object handle) => _value._standin(index, handle);
}

final class ExistsExpression extends SingleValueExpr<bool> {
  final QueryClause query;
  ExistsExpression._(this.query) : super._();

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class SumExpression<T extends num> extends SingleValueExpr<T> {
  final Expr<T> value;
  SumExpression._(this.value) : super._();

  @override
  T _decode(RowReader r) => value._decode(r);
}

final class AvgExpression extends SingleValueExpr<double> {
  final Expr<num> value;
  AvgExpression._(this.value) : super._();

  @override
  double _decode(RowReader r) => r.readDouble()!;
}

// TODO: Consider if T extends Comparable makes sense!
final class MinExpression<T extends Comparable> extends SingleValueExpr<T> {
  final Expr<T> value;
  MinExpression._(this.value) : super._();

  @override
  T _decode(RowReader r) => value._decode(r);
}

final class MaxExpression<T extends Comparable> extends SingleValueExpr<T> {
  final Expr<T> value;
  MaxExpression._(this.value) : super._();

  @override
  T _decode(RowReader r) => value._decode(r);
}

final class CountAllExpression extends SingleValueExpr<int> {
  CountAllExpression._() : super._();

  @override
  int _decode(RowReader r) => r.readInt()!;
}

final class OrElseExpression<T> extends SingleValueExpr<T> {
  final Expr<T?> value;
  final Expr<T> orElse;

  OrElseExpression._(this.value, this.orElse) : super._();

  @override
  T _decode(RowReader r) => orElse._decode(r); // What if orElse is null???
}

final class NullAssertionExpression<T> extends Expr<T> {
  final Expr<T?> value;

  @override
  int get _columns => value._columns;

  @override
  T _decode(RowReader row) => value._decode(row)!;

  @override
  Iterable<Expr<Object?>> _explode() => value._explode();

  Expr<T> _standin(int index, Object handle) =>
      NullAssertionExpression._(value._standin(index, handle));
  Expr<R> _field<R>(int index, R Function(RowReader) readValue) =>
      value._field(index, readValue);

  NullAssertionExpression._(this.value) : super._();
}

extension ExpressionNullable<T> on Expr<T?> {
  Expr<T> assertNotNull() => NullAssertionExpression._(this);
}

extension ExpressionNullableNum<T extends num> on Expr<T?> {
  Expr<T> orElse(Expr<T> value) => OrElseExpression._(this, value);
  Expr<T> orElseLiteral(T value) => orElse(literal(value));
}

extension ExpressionNullableString on Expr<String?> {
  Expr<String> orElse(Expr<String> value) => OrElseExpression._(this, value);
  Expr<String> orElseLiteral(String value) => orElse(literal(value));
}

extension ExpressionNullableBool on Expr<bool?> {
  Expr<bool> orElse(Expr<bool> value) => OrElseExpression._(this, value);
  Expr<bool> orElseLiteral(bool value) => orElse(literal(value));
}

extension ExpressionNullableDateTime on Expr<DateTime?> {
  Expr<DateTime> orElse(Expr<DateTime> value) =>
      OrElseExpression._(this, value);
  Expr<DateTime> orElseLiteral(DateTime value) => orElse(literal(value));
}

final class Literal<T> extends SingleValueExpr<T> {
  final T Function(RowReader) _readValue;
  final T value;
  // TODO: Consider supporting a Constant expression subclass, currently we
  //       always encode literals as ? and attach them as parameters.
  //       This is fine, but if we ever use this query builders to created
  //       prepared statements that are executed more than once, then it matters
  //       whether a literal is encoded as value or constant
  //       If we do this, we might have rename Literal to Value!

  static Object? _readNull(RowReader r) {
    if (!r.tryReadNull()) {
      throw AssertionError('Expr<Null> should always be `null`!');
    }
    return null;
  }

  static bool _readBool(RowReader r) => r.readBool()!;

  static const null$ = Literal._(null, _readNull);
  static const true$ = Literal._(true, _readBool);
  static const false$ = Literal._(false, _readBool);

  const Literal._(this.value, this._readValue) : super._();

  static Literal<T> custom<S, T extends CustomDataType<S>>(
    T value,
    T Function(S) fromDatabase,
  ) =>
      switch (value) {
        CustomDataType<bool> _ =>
          Literal._(value, (r) => fromDatabase(r.readBool() as S)),
        CustomDataType<int> _ =>
          Literal._(value, (r) => fromDatabase(r.readInt() as S)),
        CustomDataType<double> _ =>
          Literal._(value, (r) => fromDatabase(r.readDouble() as S)),
        CustomDataType<Uint8List> _ =>
          Literal._(value, (r) => fromDatabase(r.readUint8List() as S)),
        CustomDataType<DateTime> _ =>
          Literal._(value, (r) => fromDatabase(r.readDateTime() as S)),
        _ => throw ArgumentError.value(
            value,
            'value',
            'T in CustomDataType<T> must be String, int, double, bool, or DateTime!',
          ),
      };

  factory Literal(T value) {
    // TODO: Consider asking Lasse how to actually switch over T, because null is not a type!
    switch (value) {
      case true:
        return true$ as Literal<T>;

      case false:
        return false$ as Literal<T>;

      case null:
        return null$ as Literal<T>;

      case String _:
        return Literal._(value, (r) => r.readString() as T);
      case int _:
        return Literal._(value, (r) => r.readInt() as T);
      case double _:
        return Literal._(value, (r) => r.readDouble() as T);
      case Uint8List _:
        return Literal._(value, (r) => r.readUint8List() as T);
      case DateTime _:
        return Literal._(value, (r) => r.readDateTime() as T);

      case CustomDataType _:
        throw ArgumentError.value(
          value,
          'value',
          'Use Literal.custom for CustomDataType!',
        );

      default:
        throw ArgumentError.value(
          value,
          'value',
          'Only String, int, double, bool, null, and DateTime '
              'literals are allowed',
        );
    }
  }

  @override
  T _decode(RowReader row) => _readValue(row);
}

sealed class BinaryOperationExpression<T, R> extends SingleValueExpr<R> {
  final Expr<T> left;
  final Expr<T> right;
  BinaryOperationExpression(this.left, this.right) : super._();
}

final class ExpressionBoolNot extends SingleValueExpr<bool> {
  final Expr<bool> value;
  ExpressionBoolNot(this.value) : super._();

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionBoolAnd extends BinaryOperationExpression<bool, bool> {
  ExpressionBoolAnd(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionBoolOr extends BinaryOperationExpression<bool, bool> {
  ExpressionBoolOr(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionStringEquals
    extends BinaryOperationExpression<String, bool> {
  ExpressionStringEquals(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionStringLessThan
    extends BinaryOperationExpression<String, bool> {
  ExpressionStringLessThan(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionStringLessThanOrEqual
    extends BinaryOperationExpression<String, bool> {
  ExpressionStringLessThanOrEqual(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionStringGreaterThan
    extends BinaryOperationExpression<String, bool> {
  ExpressionStringGreaterThan(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionStringGreaterThanOrEqual
    extends BinaryOperationExpression<String, bool> {
  ExpressionStringGreaterThanOrEqual(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionStringIsEmpty extends SingleValueExpr<bool> {
  final Expr<String> value;
  ExpressionStringIsEmpty(this.value) : super._();

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionStringLength extends SingleValueExpr<int> {
  final Expr<String> value;
  ExpressionStringLength(this.value) : super._();

  @override
  int _decode(RowReader r) => r.readInt()!;
}

final class ExpressionStringStartsWith extends SingleValueExpr<bool> {
  final Expr<String> value;
  final Expr<String> prefix;
  ExpressionStringStartsWith(this.value, this.prefix) : super._();

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionStringEndsWith extends SingleValueExpr<bool> {
  final Expr<String> value;
  final Expr<String> suffix;
  ExpressionStringEndsWith(this.value, this.suffix) : super._();

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionStringLike extends SingleValueExpr<bool> {
  final Expr<String> value;
  final String pattern;
  ExpressionStringLike(this.value, this.pattern) : super._();

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionStringContains extends SingleValueExpr<bool> {
  final Expr<String> value;
  final Expr<String> needle;
  ExpressionStringContains(this.value, this.needle) : super._();

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionStringToUpperCase extends SingleValueExpr<String> {
  final Expr<String> value;
  ExpressionStringToUpperCase(this.value) : super._();

  @override
  String _decode(RowReader r) => r.readString()!;
}

final class ExpressionStringToLowerCase extends SingleValueExpr<String> {
  final Expr<String> value;
  ExpressionStringToLowerCase(this.value) : super._();

  @override
  String _decode(RowReader r) => r.readString()!;
}

final class ExpressionNumEquals<T extends num>
    extends BinaryOperationExpression<T, bool> {
  ExpressionNumEquals(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionNumAdd<T extends num>
    extends BinaryOperationExpression<T, T> {
  ExpressionNumAdd(super.left, super.right);

  @override
  T _decode(RowReader r) => left._decode(r);
}

final class ExpressionNumSubtract<T extends num>
    extends BinaryOperationExpression<T, T> {
  ExpressionNumSubtract(super.left, super.right);

  @override
  T _decode(RowReader r) => left._decode(r);
}

final class ExpressionNumMultiply<T extends num>
    extends BinaryOperationExpression<T, T> {
  ExpressionNumMultiply(super.left, super.right);

  @override
  T _decode(RowReader r) => left._decode(r);
}

final class ExpressionNumDivide<T extends num>
    extends BinaryOperationExpression<T, double> {
  ExpressionNumDivide(super.left, super.right);

  @override
  double _decode(RowReader r) => r.readDouble()!;
}

final class ExpressionNumLessThan<T extends num>
    extends BinaryOperationExpression<T, bool> {
  ExpressionNumLessThan(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionNumLessThanOrEqual<T extends num>
    extends BinaryOperationExpression<T, bool> {
  ExpressionNumLessThanOrEqual(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionNumGreaterThan<T extends num>
    extends BinaryOperationExpression<T, bool> {
  ExpressionNumGreaterThan(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionNumGreaterThanOrEqual<T extends num>
    extends BinaryOperationExpression<T, bool> {
  ExpressionNumGreaterThanOrEqual(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionDateTimeEquals
    extends BinaryOperationExpression<DateTime, bool> {
  ExpressionDateTimeEquals(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionDateTimeLessThan
    extends BinaryOperationExpression<DateTime, bool> {
  ExpressionDateTimeLessThan(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionDateTimeLessThanOrEqual
    extends BinaryOperationExpression<DateTime, bool> {
  ExpressionDateTimeLessThanOrEqual(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionDateTimeGreaterThan
    extends BinaryOperationExpression<DateTime, bool> {
  ExpressionDateTimeGreaterThan(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
}

final class ExpressionDateTimeGreaterThanOrEqual
    extends BinaryOperationExpression<DateTime, bool> {
  ExpressionDateTimeGreaterThanOrEqual(super.left, super.right);

  @override
  bool _decode(RowReader r) => r.readBool()!;
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
  Expr<double> operator /(Expr<T> other) => ExpressionNumDivide(this, other);

  Expr<T> add(Expr<T> other) => ExpressionNumAdd(this, other);
  Expr<T> subtract(Expr<T> other) => ExpressionNumSubtract(this, other);
  Expr<T> multiply(Expr<T> other) => ExpressionNumMultiply(this, other);
  Expr<double> divide(Expr<T> other) => ExpressionNumDivide(this, other);

  Expr<T> addLiteral(T other) => ExpressionNumAdd(this, literal(other));
  Expr<T> subtractLiteral(T other) =>
      ExpressionNumSubtract(this, literal(other));
  Expr<T> multiplyLiteral(T other) =>
      ExpressionNumMultiply(this, literal(other));
  Expr<double> divideLiteral(T other) =>
      ExpressionNumDivide(this, literal(other));

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
  // TODO: integerDivide!
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
