// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'real_test.dart';

// **************************************************************************
// Generator: _TypedSqlBuilder
// **************************************************************************

extension TestDatabaseSchema on DatabaseContext<TestDatabase> {
  static const _$tables = [_$Item._$table];

  /// TODO: Propagate documentation for tables!
  Table<Item> get items => ExposedForCodeGen.declareTable(
        this,
        _$Item._$table,
      );
  Future<void> createTables() async => ExposedForCodeGen.createTables(
        context: this,
        tables: _$tables,
      );
}

String createTestDatabaseTables(SqlDialect dialect) =>
    ExposedForCodeGen.createTableSchema(
      dialect: dialect,
      tables: TestDatabaseSchema._$tables,
    );

final class _$Item extends Item {
  _$Item._(
    this.id,
    this.value,
  );

  @override
  final int id;

  @override
  final double value;

  static const _$table = (
    tableName: 'items',
    columns: <String>['id', 'value'],
    columnInfo: <({
      ColumnType type,
      bool isNotNull,
      Object? defaultValue,
      bool autoIncrement,
    })>[
      (
        type: ExposedForCodeGen.integer,
        isNotNull: true,
        defaultValue: null,
        autoIncrement: true,
      ),
      (
        type: ExposedForCodeGen.real,
        isNotNull: true,
        defaultValue: null,
        autoIncrement: false,
      )
    ],
    primaryKey: <String>['id'],
    unique: <List<String>>[],
    foreignKeys: <({
      String name,
      List<String> columns,
      String referencedTable,
      List<String> referencedColumns,
    })>[],
    readModel: _$Item._$fromDatabase,
  );

  static Item? _$fromDatabase(RowReader row) {
    final id = row.readInt();
    final value = row.readDouble();
    if (id == null && value == null) {
      return null;
    }
    return _$Item._(id!, value!);
  }

  @override
  String toString() => 'Item(id: "$id", value: "$value")';
}

extension TableItemExt on Table<Item> {
  /// TODO: document insertLiteral (this cannot explicitly insert NULL for nullable fields with a default value)
  InsertSingle<Item> insertLiteral({
    int? id,
    required double value,
  }) =>
      ExposedForCodeGen.insertInto(
        table: this,
        values: [
          id != null ? literal(id) : null,
          literal(value),
        ],
      );

  /// TODO: document insert
  InsertSingle<Item> insert({
    Expr<int>? id,
    required Expr<double> value,
  }) =>
      ExposedForCodeGen.insertInto(
        table: this,
        values: [
          id,
          value,
        ],
      );

  /// TODO: document delete
  DeleteSingle<Item> delete({required int id}) =>
      ExposedForCodeGen.deleteSingle(
        byKey(id: id),
        _$Item._$table,
      );
}

extension QueryItemExt on Query<(Expr<Item>,)> {
  /// TODO: document lookup by PrimaryKey
  QuerySingle<(Expr<Item>,)> byKey({required int id}) =>
      where((item) => item.id.equalsLiteral(id)).first;

  /// TODO: document updateAll()
  Update<Item> updateAll(
          UpdateSet<Item> Function(
            Expr<Item> item,
            UpdateSet<Item> Function({
              Expr<int> id,
              Expr<double> value,
            }) set,
          ) updateBuilder) =>
      ExposedForCodeGen.update<Item>(
        this,
        _$Item._$table,
        (item) => updateBuilder(
          item,
          ({
            Expr<int>? id,
            Expr<double>? value,
          }) =>
              ExposedForCodeGen.buildUpdate<Item>([
            id,
            value,
          ]),
        ),
      );

  /// TODO: document updateAllLiteral()
  /// WARNING: This cannot set properties to `null`!
  Update<Item> updateAllLiteral({
    int? id,
    double? value,
  }) =>
      ExposedForCodeGen.update<Item>(
        this,
        _$Item._$table,
        (item) => ExposedForCodeGen.buildUpdate<Item>([
          id != null ? literal(id) : null,
          value != null ? literal(value) : null,
        ]),
      );

  /// TODO: document delete()}
  Delete<Item> delete() => ExposedForCodeGen.delete(this, _$Item._$table);
}

extension QuerySingleItemExt on QuerySingle<(Expr<Item>,)> {
  /// TODO: document update()
  UpdateSingle<Item> update(
          UpdateSet<Item> Function(
            Expr<Item> item,
            UpdateSet<Item> Function({
              Expr<int> id,
              Expr<double> value,
            }) set,
          ) updateBuilder) =>
      ExposedForCodeGen.updateSingle<Item>(
        this,
        _$Item._$table,
        (item) => updateBuilder(
          item,
          ({
            Expr<int>? id,
            Expr<double>? value,
          }) =>
              ExposedForCodeGen.buildUpdate<Item>([
            id,
            value,
          ]),
        ),
      );

  /// TODO: document updateLiteral()
  /// WARNING: This cannot set properties to `null`!
  UpdateSingle<Item> updateLiteral({
    int? id,
    double? value,
  }) =>
      ExposedForCodeGen.updateSingle<Item>(
        this,
        _$Item._$table,
        (item) => ExposedForCodeGen.buildUpdate<Item>([
          id != null ? literal(id) : null,
          value != null ? literal(value) : null,
        ]),
      );

  /// TODO: document delete()
  DeleteSingle<Item> delete() =>
      ExposedForCodeGen.deleteSingle(this, _$Item._$table);
}

extension ExpressionItemExt on Expr<Item> {
  /// TODO: document id
  Expr<int> get id =>
      ExposedForCodeGen.field(this, 0, ExposedForCodeGen.integer);

  /// TODO: document value
  Expr<double> get value =>
      ExposedForCodeGen.field(this, 1, ExposedForCodeGen.real);
}

extension ExpressionNullableItemExt on Expr<Item?> {
  /// TODO: document id
  Expr<int?> get id =>
      ExposedForCodeGen.field(this, 0, ExposedForCodeGen.integer);

  /// TODO: document value
  Expr<double?> get value =>
      ExposedForCodeGen.field(this, 1, ExposedForCodeGen.real);
}

extension ItemChecks on Subject<Item> {
  Subject<int> get id => has((m) => m.id, 'id');
  Subject<double> get value => has((m) => m.value, 'value');
}
