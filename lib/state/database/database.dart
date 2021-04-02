import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Enable FOREIGN KEY constraints
Future<void> onConfigure(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}

Future<DB> openDB() async {
  // Avoid errors caused by flutter upgrade.
  WidgetsFlutterBinding.ensureInitialized();

  // Set the path to the database. Note: Using the `join` function from the
  // `path` package is best practice to ensure the path is correctly
  // constructed for each platform.
  var path = p.join(await getDatabasesPath(), 'app.db');

  var db = await openDatabase(
    path,
    version: 1,
    onConfigure: onConfigure,
    onCreate: (db, version) {},
    onUpgrade: (db, oldVersion, newVersion) {},
  );
  return DB(database: db);
}

class DBArtist {
  final String id;
  final String name;

  DBArtist(this.id, this.name);
}

class DBCachedResponse {
  final String id;
  final String serverId;
  final String request;
  final String response;

  DBCachedResponse(this.id, this.serverId, this.request, this.response);
}

class DBServer {
  final String id;
  final String uri;
  final String username;
  final String password;

  DBServer({
    required this.id,
    required this.uri,
    required this.username,
    required this.password,
  });

  void createTableV1(Batch tx) {
    tx.execute('''
        CREATE TABLE servers (
          id TEXT PRIMARY KEY,
          uri TEXT NOT NULL,
          username TEXT NOT NULL,
          password TEXT NOT NULL
        )
        ''');
  }
}

class DB {
  final Database _database;

  DB({
    required Database database,
  }) : this._database = database;

  Future<void> close() async {
    await _database.close();
  }
}
