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

import 'package:test/test.dart';
import 'package:typed_sql/sql_dialect/sql_dialect.dart';
import 'model.dart';
import 'package:typed_sql/typed_sql.dart';

final u = Uri.parse('file:shared-inmemory?mode=memory&cache=shared');

void main() {
  test('sqlite', () async {
    final adaptor = DatabaseAdaptor.withLogging(
      DatabaseAdaptor.sqlite3(u),
      print,
    );
    final db = Database<PrimaryDatabase>(adaptor, SqlDialect.sqlite());

    await adaptor.query('''
    CREATE TABLE users (
      userId INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT NOT NULL
    )
    ''', []).drain();

    //await db.migrate();

    await db.users.create(
      userId: 22,
      name: 'Bob',
      email: 'bob@example.com',
    );
    await db.users.create(
      userId: 42,
      name: 'Alice',
      email: 'alice@example.com',
    );

    // Change all users to a have lower case email
    await db.users.updateAll((u, set) => set(
          email: u.email.toLowerCase(),
        ));

    // Update user 42 to have new name!
    await db.users
        .where((u) => u.userId.equals(literal(42)))
        .first
        .update((u, set) => set(
              name: literal('jonasfj'),
            ));

    print(
      await db.users
          .join(db.users)
          .on((u1, u2) => u1.userId.equals(u2.userId))
          .fetch()
          .toList(),
    );

    // Update user 42 to have new name, using short-cuts
    await db.users.byKey(userId: 42).update((u, set) => set(
          name: literal('jonasfj'),
        ));
    // Update user 42 to have new name, using updateLiteral
    await db.users.byKey(userId: 42).updateLiteral(
          name: 'jonasfj',
        );

    final email = await db.users
        .byKey(userId: 42)
        .select((user) => (user.email,))
        .fetch();
    if (email != null) {
      print('email: $email');
    }

    // TODO: Consider a fetchOrThrow or fetchOrNulls
    final result = await db.users
        .byKey(userId: 42)
        .select((user) => (user.email, user.name))
        .fetch();
    if (result != null) {
      final (email, name) = result;
      print('$name has $email');
    }

    final users = await db.users.fetch().toList();
    print(users);

    final alice = await db.users
        .where((u) => u.name.equalsLiteral('Alice'))
        .first
        .fetch();
    print(alice);

    await db.users.byKey(userId: 42).delete();

    {
      final users = await db.users.fetch().toList();
      print(users);
    }

    await adaptor.close();
  });
}
