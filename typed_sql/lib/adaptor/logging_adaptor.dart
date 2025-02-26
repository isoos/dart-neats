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

import 'adaptor.dart';

DatabaseAdaptor loggingAdaptor(
  DatabaseAdaptor adaptor,
  void Function(String message) logDrain,
) =>
    _LoggingDatabaseAdaptor(adaptor, logDrain);

final class _LoggingDatabaseAdaptor extends DatabaseAdaptor {
  final DatabaseAdaptor _adaptor;
  final void Function(String message) _log;

  _LoggingDatabaseAdaptor(this._adaptor, this._log);

  @override
  Future<void> close({bool force = false}) async {
    _log('db.close(force: $force)');
    await _adaptor.close(force: force);
  }

  @override
  Stream<RowReader> query(String sql, List<Object?> params) async* {
    _log('db.query("$sql", [${params.join(', ')}])');
    yield* _adaptor.query(sql, params);
  }

  @override
  Future<QueryResult> execute(String sql, List<Object?> params) async {
    _log('db.execute("$sql", [${params.join(', ')}])');
    return await _adaptor.execute(sql, params);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(DatabaseTransaction tx) fn,
  ) async {
    _log('db.transaction()');
    return await _adaptor.transaction((tx) async {
      return await fn(_LoggingDatabaseTransaction(tx, _log));
    });
  }
}

final class _LoggingDatabaseTransaction extends DatabaseTransaction {
  final DatabaseTransaction _tx;
  final void Function(String message) _log;

  _LoggingDatabaseTransaction(this._tx, this._log);

  @override
  Stream<RowReader> query(String sql, List<Object?> params) async* {
    _log('tx.query("$sql", [${params.join(', ')}])');
    yield* _tx.query(sql, params);
  }

  @override
  Future<QueryResult> execute(String sql, List<Object?> params) async {
    _log('tx.execute("$sql", [${params.join(', ')}])');
    return await _tx.execute(sql, params);
  }

  @override
  Future<T> savePoint<T>(Future<T> Function(DatabaseSavePoint sp) fn) async {
    _log('tx.savePoint()');
    return await _tx.savePoint((sp) async {
      return await fn(_LoggingDatabaseSavePoint(sp, _log));
    });
  }
}

final class _LoggingDatabaseSavePoint extends DatabaseSavePoint {
  final DatabaseSavePoint _sp;
  final void Function(String message) _log;

  _LoggingDatabaseSavePoint(this._sp, this._log);

  @override
  Stream<RowReader> query(String sql, List<Object?> params) async* {
    _log('sp.query("$sql", [${params.join(', ')}])');
    yield* _sp.query(sql, params);
  }

  @override
  Future<QueryResult> execute(String sql, List<Object?> params) async {
    _log('sp.execute("$sql", [${params.join(', ')}])');
    return await _sp.execute(sql, params);
  }

  @override
  Future<T> savePoint<T>(Future<T> Function(DatabaseSavePoint sp) fn) async {
    _log('sp.savePoint()');
    return await _sp.savePoint((sp) async {
      return await fn(_LoggingDatabaseSavePoint(sp, _log));
    });
  }
}
