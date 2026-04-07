import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = join(await getDatabasesPath(), 'groupevent.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        name     TEXT    NOT NULL,
        email    TEXT    NOT NULL UNIQUE,
        password TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE session (
        id      INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        title        TEXT    NOT NULL,
        date         TEXT    NOT NULL,
        location     TEXT    NOT NULL DEFAULT '',
        participants INTEGER NOT NULL DEFAULT 1,
        budget       REAL    NOT NULL DEFAULT 0,
        description  TEXT    DEFAULT '',
        creator_id   INTEGER,
        FOREIGN KEY (creator_id) REFERENCES users(id)
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN name TEXT NOT NULL DEFAULT ""');
      } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS session (
          id      INTEGER PRIMARY KEY,
          user_id INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS events (
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          title        TEXT    NOT NULL,
          date         TEXT    NOT NULL,
          location     TEXT    NOT NULL DEFAULT '',
          participants INTEGER NOT NULL DEFAULT 1,
          budget       REAL    NOT NULL DEFAULT 0,
          description  TEXT    DEFAULT '',
          creator_id   INTEGER
        )
      ''');
    }
  }

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await database;
    final existing = await db.query(
      'users',
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email],
    );
    if (existing.isNotEmpty) return null;

    final hashed = _hashPassword(password);
    final id = await db.insert('users', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': hashed,
    });

    return UserModel(id: id, name: name.trim(), email: email.trim().toLowerCase(), password: hashed);
  }

  static Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final hashed = _hashPassword(password);

    final result = await db.query(
      'users',
      where: 'LOWER(email) = LOWER(?) AND password = ?',
      whereArgs: [email.trim().toLowerCase(), hashed],
    );

    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  static Future<void> saveSession(int userId) async {
    final db = await database;
    await db.delete('session');
    await db.insert('session', {'id': 1, 'user_id': userId});
  }

  static Future<UserModel?> getSessionUser() async {
    final db = await database;
    final sessionRows = await db.query('session', where: 'id = 1');
    if (sessionRows.isEmpty) return null;

    final userId = sessionRows.first['user_id'] as int;
    final userRows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (userRows.isEmpty) return null;
    return UserModel.fromMap(userRows.first);
  }

  static Future<void> clearSession() async {
    final db = await database;
    await db.delete('session');
  }

  static Future<int> insertEvent(EventModel event) async {
    final db = await database;
    return await db.insert('events', event.toMap());
  }

  static Future<List<EventModel>> getEventsByUser(int userId) async {
    final db = await database;
    final rows = await db.query(
      'events',
      where: 'creator_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map((r) => EventModel.fromMap(r)).toList();
  }

  static Future<void> deleteEvent(int eventId) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [eventId]);
  }
}
