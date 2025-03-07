// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blob_test.dart';

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
  _$Item(RowReader row)
      : id = row.readInt()!,
        value = row.readUint8List()!;

  @override
  final int id;

  @override
  final Uint8List value;

  static const _$table = (
    tableName: 'items',
    columns: <String>['id', 'value'],
    columnInfo: <({
      Type type,
      bool isNotNull,
      Object? defaultValue,
      bool autoIncrement,
    })>[
      (
        type: int,
        isNotNull: true,
        defaultValue: null,
        autoIncrement: true,
      ),
      (
        type: Uint8List,
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
    readModel: _$Item.new,
  );

  @override
  String toString() => 'Item(id: "$id", value: "$value")';
}

extension TableItemExt on Table<Item> {
  /// TODO: document create
  Future<Item> create({
    required int id,
    required Uint8List value,
  }) =>
      ExposedForCodeGen.insertInto(
        table: this,
        values: [
          literal(id),
          literal(value),
        ],
      );

  /// TODO: document insert
  Future<Item> insert({
    required Expr<int> id,
    required Expr<Uint8List> value,
  }) =>
      ExposedForCodeGen.insertInto(
        table: this,
        values: [
          id,
          value,
        ],
      );

  /// TODO: document delete
  Future<void> delete({required int id}) => byKey(id: id).delete();
}

extension QueryItemExt on Query<(Expr<Item>,)> {
  /// TODO: document lookup by PrimaryKey
  QuerySingle<(Expr<Item>,)> byKey({required int id}) =>
      where((item) => item.id.equalsLiteral(id)).first;

  /// TODO: document updateAll()
  Future<void> updateAll(
          Update<Item> Function(
            Expr<Item> item,
            Update<Item> Function({
              Expr<int> id,
              Expr<Uint8List> value,
            }) set,
          ) updateBuilder) =>
      ExposedForCodeGen.update<Item>(
        this,
        _$Item._$table,
        (item) => updateBuilder(
          item,
          ({
            Expr<int>? id,
            Expr<Uint8List>? value,
          }) =>
              ExposedForCodeGen.buildUpdate<Item>([
            id,
            value,
          ]),
        ),
      );

  /// TODO: document updateAllLiteral()
  /// WARNING: This cannot set properties to `null`!
  Future<void> updateAllLiteral({
    int? id,
    Uint8List? value,
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
  Future<int> delete() => ExposedForCodeGen.delete(this, _$Item._$table);
}

extension QuerySingleItemExt on QuerySingle<(Expr<Item>,)> {
  /// TODO: document update()
  Future<void> update(
          Update<Item> Function(
            Expr<Item> item,
            Update<Item> Function({
              Expr<int> id,
              Expr<Uint8List> value,
            }) set,
          ) updateBuilder) =>
      ExposedForCodeGen.update<Item>(
        asQuery,
        _$Item._$table,
        (item) => updateBuilder(
          item,
          ({
            Expr<int>? id,
            Expr<Uint8List>? value,
          }) =>
              ExposedForCodeGen.buildUpdate<Item>([
            id,
            value,
          ]),
        ),
      );

  /// TODO: document updateLiteral()
  /// WARNING: This cannot set properties to `null`!
  Future<void> updateLiteral({
    int? id,
    Uint8List? value,
  }) =>
      ExposedForCodeGen.update<Item>(
        asQuery,
        _$Item._$table,
        (item) => ExposedForCodeGen.buildUpdate<Item>([
          id != null ? literal(id) : null,
          value != null ? literal(value) : null,
        ]),
      );

  /// TODO: document delete()
  Future<int> delete() => asQuery.delete();
}

extension ExpressionItemExt on Expr<Item> {
  /// TODO: document id
  Expr<int> get id => ExposedForCodeGen.field(this, 0, (r) => r.readInt()!);

  /// TODO: document value
  Expr<Uint8List> get value =>
      ExposedForCodeGen.field(this, 1, (r) => r.readUint8List()!);
}

extension ItemChecks on Subject<Item> {
  Subject<int> get id => has((m) => m.id, 'id');
  Subject<Uint8List> get value => has((m) => m.value, 'value');
}
