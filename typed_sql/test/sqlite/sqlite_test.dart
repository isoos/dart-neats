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

import 'dart:async';

import 'package:test/test.dart';
import 'package:typed_sql/sql_dialect/sql_dialect.dart';
import 'package:typed_sql/typed_sql.dart';

import 'model.dart';

final u = Uri.parse('file:shared-inmemory?mode=memory&cache=shared');

void _test(
  String name,
  FutureOr<void> Function(Database<PrimaryDatabase> db) fn,
) async {
  test(name, () async {
    final adaptor = DatabaseAdaptor.withLogging(
      DatabaseAdaptor.sqlite3(u),
      printOnFailure,
      //print,
    );
    final db = Database<PrimaryDatabase>(adaptor, SqlDialect.sqlite());
    await adaptor.createTables();
    try {
      await db.users.create(
        userId: 1,
        name: 'Alice',
        email: 'alice@example.com',
      );
      await db.users.create(userId: 2, name: 'Bob', email: 'bob@example.com');
      await db.packages.create(
        packageName: 'foo',
        likes: 2,
        publisher: null,
        ownerId: 1,
      );
      await db.packages.create(
        packageName: 'bar',
        likes: 3,
        publisher: null,
        ownerId: 1,
      );
      await db.likes.create(userId: 1, packageName: 'foo');
      await db.likes.create(userId: 2, packageName: 'foo');
      await fn(db);
    } finally {
      await adaptor.close();
    }
  });
}

void main() {
  _test('db.users.create()', (db) async {
    // Do nothing, this is covered in the setup
  });

  _test('db.packages.insert()', (db) async {
    await db.packages.insert(
      packageName: literal('foobar'),
      likes: literal(0),
      publisher: literal(null),
      ownerId: literal(2),
    );
  });

  _test('db.users.where(.endsWithLiteral).select()', (db) async {
    final users = await db.users
        .where((u) => u.email.endsWithLiteral('@example.com'))
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(users, contains('Alice'));
    expect(users, contains('Bob'));
    expect(users, hasLength(2));
  });

  _test('db.users.where(.startsWithLiteral).select()', (db) async {
    final users = await db.users
        .where((u) => u.email.startsWithLiteral('alice@'))
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(users, contains('Alice'));
    expect(users, hasLength(1));
  });

  _test('db.packages.where().updateAllLiteral()', (db) async {
    {
      final p = await db.packages.byKey(packageName: 'foo').fetch();
      expect(p!.ownerId, equals(1));
    }
    await db.packages
        .where((p) => p.packageName.equalsLiteral('foo'))
        .updateAllLiteral(
          ownerId: 2,
        );
    {
      final p = await db.packages.byKey(packageName: 'foo').fetch();
      expect(p!.ownerId, equals(2));
    }
  });

  _test('db.packages.byKey().update(.add / .subtract)', (db) async {
    expect(
      await db.packages
          .byKey(packageName: 'foo')
          .select((p) => (p.likes,))
          .fetch(),
      equals(2),
    );

    await db.packages.byKey(packageName: 'foo').update((u, set) => set(
          likes: u.likes + literal(1),
        ));

    expect(
      await db.packages
          .byKey(packageName: 'foo')
          .select((p) => (p.likes,))
          .fetch(),
      equals(3),
    );

    await db.packages.byKey(packageName: 'foo').update((u, set) => set(
          likes: u.likes.addLiteral(1),
        ));

    expect(
      await db.packages
          .byKey(packageName: 'foo')
          .select((p) => (p.likes,))
          .fetch(),
      equals(4),
    );

    await db.packages.byKey(packageName: 'foo').update((u, set) => set(
          likes: u.likes.subtractLiteral(1),
        ));

    await db.packages.byKey(packageName: 'foo').update((u, set) => set(
          likes: u.likes - literal(1),
        ));

    expect(
      await db.packages
          .byKey(packageName: 'foo')
          .select((p) => (p.likes,))
          .fetch(),
      equals(2),
    );
  });

  _test('db.packages.byKey().delete()', (db) async {
    {
      final p = await db.packages.byKey(packageName: 'foo').fetch();
      expect(p, isNotNull);
    }
    final count = await db.packages.byKey(packageName: 'foo').delete();
    expect(count, 1);
    {
      final p = await db.packages.byKey(packageName: 'foo').fetch();
      expect(p, isNull);
    }
  });

  _test('db.packages.where().deleteAll()', (db) async {
    {
      final packages = await db.packages.fetch().toList();
      expect(packages, hasLength(2));
    }
    await db.packages.where((p) => p.packageName.equalsLiteral('foo')).delete();
    {
      final packages = await db.packages.fetch().toList();
      expect(packages, hasLength(1));
    }
  });

  _test('db.users.where().limit()', (db) async {
    final users = await db.users
        .where((u) => u.email.equalsLiteral('alice@example.com'))
        .limit(1)
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(users, contains('Alice'));
    expect(users, hasLength(1));
  });

  _test('db.users.limit().where()', (db) async {
    final users = await db.users
        .limit(2)
        .where((u) => u.email.equalsLiteral('alice@example.com'))
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(users, contains('Alice'));
    expect(users, hasLength(1));
  });

  _test('db.users.offset(0).limit().where()', (db) async {
    final users = await db.users
        .offset(0)
        .limit(2)
        .where((u) => u.email.equalsLiteral('bob@example.com'))
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(users, contains('Bob'));
    expect(users, hasLength(1));
  });

  _test('db.users.limit(0).offset().where()', (db) async {
    final users = await db.users
        .limit(2)
        .offset(0)
        .where((u) => u.email.equalsLiteral('bob@example.com'))
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(users, contains('Bob'));
    expect(users, hasLength(1));
  });

  _test('db.users.orderBy().offset().where(1) (empty)', (db) async {
    final users = await db.users
        .orderBy((u) => u.userId)
        .offset(1)
        .where((u) => u.email.equalsLiteral('alice@example.com'))
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(users, isEmpty);
  });

  _test('db.users.orderBy().offset(1).where()', (db) async {
    final users = await db.users
        .orderBy((u) => u.userId)
        .offset(1)
        .where((u) => u.email.equalsLiteral('bob@example.com'))
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(users, contains('Bob'));
    expect(users, hasLength(1));
  });

  _test('db.users.orderBy(descending).offset(1).where() (empty)', (db) async {
    final users = await db.users
        .orderBy((u) => u.userId, descending: true)
        .offset(1)
        .where((u) => u.email.equalsLiteral('bob@example.com'))
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(users, isEmpty);
  });

  _test('db.users.orderBy(descending).offset(1).where()', (db) async {
    final users = await db.users
        .orderBy((u) => u.userId, descending: true)
        .offset(1)
        .where((u) => u.email.equalsLiteral('alice@example.com'))
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(users, contains('Alice'));
    expect(users, hasLength(1));
  });

  _test('db.users.join(db.packages).on()', (db) async {
    final result = await db.users
        .join(db.packages)
        .on((u, p) => u.userId.equals(p.ownerId))
        .fetch()
        .toList();
    expect(result, hasLength(2));
    final (u, p) = result[0];
    expect(u.name, equals('Alice'));
    expect(p.packageName, anyOf(equals('foo'), equals('bar')));
  });

  _test('db.users.join(db.packages).on().select()', (db) async {
    final result = await db.users
        .join(db.packages)
        .on((u, p) => u.userId.equals(p.ownerId))
        .select((u, p) => (u.name, p.packageName))
        .fetch()
        .toList();
    expect(result, contains(('Alice', 'foo')));
    expect(result, hasLength(2));
  });

  _test('db.users.byKey().asQuery.join(db.packages).on().select()', (db) async {
    final result = await db.users
        .byKey(userId: 1)
        .asQuery
        .join(db.packages)
        .on((u, p) => u.userId.equals(p.ownerId))
        .select((u, p) => (u.name, p.packageName))
        .fetch()
        .toList();
    expect(result, contains(('Alice', 'foo')));
    expect(result, hasLength(2));
  });

  _test('db.users.byKey().asQuery.join(db.packages).on() (empty)', (db) async {
    final result = await db.users
        .byKey(userId: 2)
        .asQuery
        .join(db.packages)
        .on((u, p) => u.userId.equals(p.ownerId))
        .fetch()
        .toList();
    expect(result, hasLength(0));
  });

  _test('db.users.join(db.packages.where().select()).on()', (db) async {
    final result = await db.users
        .join(
          db.packages
              .where((p) => p.likes > literal(1))
              .select((p) => (p.packageName, p.ownerId)),
        )
        .on((u, packageName, ownerId) => u.userId.equals(ownerId))
        .fetch()
        .toList();
    expect(result, hasLength(2));
    final (u, packageName, ownerId) = result[0];
    expect(u.name, equals('Alice'));
    expect(packageName, anyOf(equals('foo'), equals('bar')));
    expect(ownerId, equals(1));
  });

  _test('db.users.join(db.packages.select().where().select()).on()',
      (db) async {
    final result = await db.users
        .join(
          db.packages
              .select((p) => (p.packageName, p.ownerId, p.likes))
              .where((packageName, ownerId, likes) => likes > literal(1))
              .select((packageName, ownerId, likes) => (packageName, ownerId)),
        )
        .on((u, packageName, ownerId) => u.userId.equals(ownerId))
        .fetch()
        .toList();
    expect(result, hasLength(2));
    final (u, packageName, ownerId) = result[0];
    expect(u.name, equals('Alice'));
    expect(packageName, anyOf(equals('foo'), equals('bar')));
    expect(ownerId, equals(1));
  });

  _test('db.packages.select(db.users.where().select().first)', (db) async {
    final result = await db.packages
        .select(
          (p) => (
            p,
            db.users
                .where((u) => u.userId.equals(p.ownerId))
                .select((u) => (u.name,))
                .first
                .asExpr
          ),
        )
        .fetch()
        .toList();
    expect(result, hasLength(2));
    final (p, name) = result[0];
    expect(p.packageName, anyOf(equals('foo'), equals('bar')));
    expect(name, equals('Alice'));
  });

  _test('db.packages.select(db.users.where().first)', (db) async {
    final result = await db.packages
        .select(
          (p) => (
            p,
            // This isn't efficient, but we can do it!
            db.users.where((u) => u.userId.equals(p.ownerId)).first.asExpr,
          ),
        )
        .fetch()
        .toList();
    expect(result, hasLength(2));
    final (p, user) = result[0];
    expect(p.packageName, anyOf(equals('foo'), equals('bar')));
    expect(user.name, equals('Alice'));
  });

  _test('db.select(true, "hello world", 42)', (db) async {
    final result = await db.select((
      literal(true),
      literal('hello world'),
      literal(42),
    )).fetch();
    expect(result, equals((true, 'hello world', 42)));
  });

  _test('db.select(true && false)', (db) async {
    final result = await db.select(
      (literal(true) & literal(false),),
    ).fetch();
    expect(result, isFalse);
  });

  _test('db.select(true || false)', (db) async {
    final result = await db.select(
      (literal(true) | literal(false),),
    ).fetch();
    expect(result, isTrue);
  });

  _test('db.select(true.not)', (db) async {
    final result = await db.select(
      (literal(true).not(),),
    ).fetch();
    expect(result, isFalse);
  });

  _test('db.select(true.not())', (db) async {
    final result = await db.select(
      (literal(true).not(),),
    ).fetch();
    expect(result, isFalse);
  });

  _test('db.select(true.and(false))', (db) async {
    final result = await db.select(
      (literal(true).and(literal(false)),),
    ).fetch();
    expect(result, isFalse);
  });

  _test('db.select(true.or(false))', (db) async {
    final result = await db.select(
      (literal(true).or(literal(false)),),
    ).fetch();
    expect(result, isTrue);
  });

  _test('db.select(42.add(1))', (db) async {
    final result = await db.select(
      (literal(42).add(literal(1)),),
    ).fetch();
    expect(result, equals(43));
  });

  _test('db.select(42.subtract(1))', (db) async {
    final result = await db.select(
      (literal(42).subtract(literal(1)),),
    ).fetch();
    expect(result, equals(41));
  });

  _test('db.select(42.multiply(2))', (db) async {
    final result = await db.select(
      (literal(42).multiply(literal(2)),),
    ).fetch();
    expect(result, equals(84));
  });

  _test('db.select(42.divide(2))', (db) async {
    final result = await db.select(
      (literal(42).divide(literal(2)),),
    ).fetch();
    expect(result, equals(21));
  });

  _test('db.select(42.equals(42))', (db) async {
    final result = await db.select(
      (literal(42).equals(literal(42)),),
    ).fetch();
    expect(result, isTrue);
  });

  _test('db.packages.exists()', (db) async {
    final result = await db.packages.exists().fetch();
    expect(result, isTrue);
  });

  _test('db.packages.exists().asExpr', (db) async {
    final result = await db.select((db.packages.exists().asExpr,)).fetch();
    expect(result, isTrue);
  });

  _test('db.packages.exists().asExpr.not()', (db) async {
    final result =
        await db.select((db.packages.exists().asExpr.not(),)).fetch();
    expect(result, isFalse);
  });

  _test('db.users.select(db.packages.where().isNotEmpty)', (db) async {
    final result = await db.users
        .select(
          (u) => (
            u,
            db.packages
                .where((p) => p.ownerId.equals(u.userId))
                .exists()
                .asExpr,
          ),
        )
        .fetch()
        .toList();
    expect(result, hasLength(2));
    final (user1, hasPackage1) = result[0];
    final (user2, hasPackage2) = result[1];
    expect(user1.name, equals('Alice'));
    expect(hasPackage1, isTrue);
    expect(user2.name, equals('Bob'));
    expect(hasPackage2, isFalse);
  });

  _test('db.users.select(db.packages.where().isEmpty)', (db) async {
    final result = await db.users
        .select(
          (u) => (
            u,
            db.packages
                .where((p) => p.ownerId.equals(u.userId))
                .exists()
                .asExpr
                .not(),
          ),
        )
        .fetch()
        .toList();
    expect(result, hasLength(2));
    final (user1, hasPackage1) = result[0];
    final (user2, hasPackage2) = result[1];
    expect(user1.name, equals('Alice'));
    expect(hasPackage1, isFalse);
    expect(user2.name, equals('Bob'));
    expect(hasPackage2, isTrue);
  });

  _test('db.users.where(db.packages.where().isEmpty)', (db) async {
    final result = await db.users
        .where(
          (u) => db.packages
              .where((p) => p.ownerId.equals(u.userId))
              .exists()
              .asExpr
              .not(),
        )
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(result, hasLength(1));
    expect(result, contains('Bob'));
  });

  _test('db.users.where(db.packages.where().isNotEmpty)', (db) async {
    final result = await db.users
        .where(
          (u) => db.packages
              .where((p) => p.ownerId.equals(u.userId))
              .exists()
              .asExpr,
        )
        .select((u) => (u.name,))
        .fetch()
        .toList();
    expect(result, hasLength(1));
    expect(result, contains('Alice'));
  });

  _test('select((u, p) => (owner: u.name, packages: p.packageName))',
      (db) async {
    final result = await db.users
        .join(db.packages)
        .on((u, p) => p.ownerId.equals(u.userId))
        .select((u, p) => (
              owner: u.name,
              package: p.packageName,
            ))
        .fetch()
        .toList();
    expect(result, hasLength(2));
    expect(result[0].owner, equals('Alice'));
    expect(result[0].package, anyOf(equals('foo'), equals('bar')));
  });

  _test('db.likes.select().sum()', (db) async {
    final result = await db.packages.select((p) => (p.likes,)).sum().fetch();
    expect(result, equals(5));
  });

  _test('db.likes.select().avg()', (db) async {
    final result = await db.packages.select((p) => (p.likes,)).avg().fetch();
    expect(result, equals(2.5));
  });

  _test('db.likes.select().min()', (db) async {
    final result = await db.packages.select((p) => (p.likes,)).min().fetch();
    expect(result, equals(2));
  });

  _test('db.likes.select().max()', (db) async {
    final result = await db.packages.select((p) => (p.likes,)).max().fetch();
    expect(result, equals(3));
  });

  _test('db.likes.count()', (db) async {
    final result = await db.likes.count().fetch();
    expect(result, equals(2));
  });

  _test('db.likes.select().count()', (db) async {
    final result =
        await db.likes.select((l) => (l.packageName,)).count().fetch();
    expect(result, equals(2));
  });

  _test('db.likes.where().select().count()', (db) async {
    final result = await db.likes
        .where((l) => l.packageName.equalsLiteral('bar'))
        .select((l) => (l.packageName,))
        .count()
        .fetch();
    expect(result, equals(0));
  });

  _test('db.packages.select(ownerId).distinct()', (db) async {
    final result = await db.packages
        .select((p) => (p.ownerId,))
        .distinct()
        .fetch()
        .toList();
    expect(result, hasLength(1));
    expect(result, contains(1));
  });

  _test('db.packages.distinct()', (db) async {
    final result = await db.packages.distinct().fetch().toList();
    expect(result, hasLength(2));
    expect(result[0].packageName, anyOf(equals('foo'), equals('bar')));
  });

  _test('db.packages.union(db.packages)', (db) async {
    final result = await db.packages.union(db.packages).fetch().toList();
    expect(result, hasLength(2));
  });

  _test('db.packages.unionAll(db.packages)', (db) async {
    final result = await db.packages.unionAll(db.packages).fetch().toList();
    expect(result, hasLength(4));
  });

  _test('db.packages.intersect(db.packages)', (db) async {
    final result = await db.packages.intersect(db.packages).fetch().toList();
    expect(result, hasLength(2));
  });

  _test('db.packages.except(db.packages)', (db) async {
    final result = await db.packages.except(db.packages).fetch().toList();
    expect(result, hasLength(0));
  });

  _test('db.users.select((u) => u.packages.countAll())', (db) async {
    final result = await db.users
        .select(
          (u) => (
            userName: u.name,
            packages: u.packages.count(),
            totalLikes: u.packages.select((p) => (p.likes,)).sum(),
          ),
        )
        .orderBy((r) => r.userName)
        .fetch()
        .toList();
    expect(result, hasLength(2));
    expect(result[0].userName, equals('Alice'));
    expect(result[0].packages, equals(2));
    expect(result[0].totalLikes, equals(5));
    expect(result[1].userName, equals('Bob'));
    expect(result[1].packages, equals(0));
    expect(result[1].totalLikes, equals(0));
  });

  _test('db.packages.select((p) => p, p.owner)', (db) async {
    final result = await db.packages
        .select((p) => (
              p,
              p.owner,
            ))
        .fetch()
        .toList();
    expect(result, hasLength(2));
  });

  _test('db.packages.select((p) => p.packageName, p.owner.name)', (db) async {
    final result = await db.packages
        .select((p) => (
              p.packageName,
              p.owner.name,
            ))
        .fetch()
        .toList();
    expect(result, hasLength(2));
    expect(result, contains(('foo', 'Alice')));
    expect(result, contains(('bar', 'Alice')));
  });

  // TODO: Support operators on nullable values!
  /*_test('db.packages.where(publisher == null).select()', (db) async {
    final result = await db.packages
        .where((p) => p.publisher.equals(Expr.null$))
        .select((p) => (p.packageName,))
        .fetch()
        .toList();
    expect(result, contains('foo'));
    expect(result, hasLength(1));
  });*/
}

// ignore_for_file: unreachable_from_main
