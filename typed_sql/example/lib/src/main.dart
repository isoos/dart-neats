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
import 'model.dart';

Future<void> main() async {
  final dynamic conn = null; // TODO: Get hold of a DatabaseConnectionPool
  final dynamic dialect = null; // TODO: Get hold of an SqlDialect object
  // ignore: argument_type_not_assignable
  final db = Database<PrimaryDatabase>(conn, dialect);

  //await db.migrate();

  // Create 3 users
  await db.users
      .create(userId: 12, name: 'alice', email: 'alice@wonderland.com');
  await db.users.create(userId: 13, name: 'trudy', email: 'trudy@evil.inc');
  await db.users.create(userId: 14, name: 'bob', email: 'bob@builders.com');

  // Create two packages
  await db.packages.create(
    packageName: 'try',
    ownerId: 12,
    likes: 0,
    publisher: null,
  );
  await db.packages.create(
    packageName: 'retry',
    ownerId: 12,
    likes: 0,
    publisher: null,
  );

  // Create some likes
  await db.likes.create(userId: 12, packageName: 'retry');
  await db.likes.create(userId: 13, packageName: 'try');
  await db.likes.create(userId: 14, packageName: 'retry');

  // Try to fetch all users
  {
    final users = await db.users.fetch().toList();
    assert(users.length == 2);
  }

  // List alice and all her liked packages
  {
    final email = 'alice@wonderland.com';
    final user = await db.users.byEmail(email).fetch();
    if (user != null) {
      print('${user.email} has liked');
      final queryLikes =
          db.likes.where((like) => like.userId.equalsLiteral(user.userId));
      await for (final like in queryLikes.fetch()) {
        print(like.packageName);
      }
    } else {
      print('Could not find user');
    }
  }

  // List packages with more than zero likes
  {
    // TODO: ...
  }

  {
    final users = await db.users
        .where((user) => user.email.endsWithLiteral('@google.com'))
        .orderBy((user) => user.email)
        .offset(5)
        .limit(10)
        .fetch()
        .toList();
    print(users.first.email);
  }

  // List users who has liked a package that has more than 1 likes
  // This essentially users that like packages other people like.
  {
    // TODO: ...
  }

  // We can do transactions
  {
    await db.transaction((tx) async {
      await tx.users
          .where((u) => u.email.endsWithLiteral('@google.com'))
          .fetch()
          .toList();
      await tx.likes
          .where((l) => l.packageName.startsWithLiteral('_').not())
          .fetch()
          .toList();

      await tx.savePoint((sp) async {
        await sp.users.byEmail('user@example.com').delete();

        await sp.savePoint((sp) async {
          await sp.users.create(
            userId: 42,
            name: 'user',
            email: 'user@example.com',
          );
        });
      });
    });
  }
}
