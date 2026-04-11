import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/event_model.dart';
import '../models/guest_model.dart';
import '../models/task_model.dart';

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
    return await openDatabase(path, version: 9, onCreate: _onCreate, onUpgrade: _onUpgrade);
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
        latitude     REAL,
        longitude    REAL,
        participants INTEGER NOT NULL DEFAULT 1,
        budget       REAL    NOT NULL DEFAULT 0,
        description  TEXT    DEFAULT '',
        creator_id   INTEGER,
        invite_code  TEXT    UNIQUE,
        FOREIGN KEY (creator_id) REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE guests (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id    INTEGER NOT NULL,
        name        TEXT    NOT NULL,
        email       TEXT,
        rsvp_status TEXT    NOT NULL DEFAULT 'pending',
        user_id     INTEGER,
        FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id)  REFERENCES users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE tasks (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id             INTEGER NOT NULL,
        title                TEXT    NOT NULL,
        is_done              INTEGER NOT NULL DEFAULT 0,
        assigned_to_guest_id INTEGER,
        assigned_to_user_id  INTEGER,
        FOREIGN KEY (event_id)             REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY (assigned_to_guest_id) REFERENCES guests(id),
        FOREIGN KEY (assigned_to_user_id)  REFERENCES users(id)
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 9) {
      await db.execute('DROP TABLE IF EXISTS tasks');
      await db.execute('DROP TABLE IF EXISTS guests');
      await db.execute('DROP TABLE IF EXISTS events');
      await db.execute('DROP TABLE IF EXISTS session');
      await db.execute('DROP TABLE IF EXISTS users');
      await _onCreate(db, newVersion);
    }
  }

  static String _hashPassword(String p) =>
      sha256.convert(utf8.encode(p)).toString();

  static Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await database;
    final existing = await db.query('users', where: 'LOWER(email) = LOWER(?)', whereArgs: [email]);
    if (existing.isNotEmpty) return null;
    final id = await db.insert('users', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': _hashPassword(password),
    });
    return UserModel(id: id, name: name.trim(), email: email.trim().toLowerCase(), password: _hashPassword(password));
  }

  static Future<UserModel?> login({required String email, required String password}) async {
    final db = await database;
    final result = await db.query('users',
        where: 'LOWER(email) = LOWER(?) AND password = ?',
        whereArgs: [email.trim().toLowerCase(), _hashPassword(password)]);
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users',
        where: 'LOWER(email) = LOWER(?)', whereArgs: [email.trim().toLowerCase()]);
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
    final rows = await db.query('events',
        where: 'creator_id = ?', whereArgs: [userId], orderBy: 'id DESC');
    return rows.map((r) => EventModel.fromMap(r)).toList();
  }

  static Future<List<EventModel>> getInvitedEvents(int userId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT e.* FROM events e
      INNER JOIN guests g ON g.event_id = e.id
      WHERE g.user_id = ? AND e.creator_id != ?
    ''', [userId, userId]);
    return rows.map((r) => EventModel.fromMap(r)).toList();
  }

  static Future<void> deleteEvent(int eventId) async {
    final db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [eventId]);
  }

  static Future<int> addGuest(GuestModel guest) async {
    final db = await database;
    return await db.insert('guests', guest.toMap());
  }

  static Future<List<GuestModel>> getGuestsForEvent(int eventId) async {
    final db = await database;
    final rows = await db.query('guests', where: 'event_id = ?', whereArgs: [eventId]);
    return rows.map((r) => GuestModel.fromMap(r)).toList();
  }

  static Future<void> updateGuestRsvp(int guestId, RsvpStatus status) async {
    final db = await database;
    await db.update('guests', {'rsvp_status': status.name}, where: 'id = ?', whereArgs: [guestId]);
  }

  static Future<void> deleteGuest(int guestId) async {
    final db = await database;
    await db.delete('guests', where: 'id = ?', whereArgs: [guestId]);
  }

  static Future<bool> isAlreadyInvited(String email, int eventId) async {
    final db = await database;
    final rows = await db.query('guests',
        where: 'LOWER(email) = LOWER(?) AND event_id = ?',
        whereArgs: [email.trim().toLowerCase(), eventId]);
    return rows.isNotEmpty;
  }

  static Future<int> insertTask(TaskModel task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  static Future<List<TaskModel>> getTasksForEvent(int eventId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT t.*, COALESCE(g.name, u.name) AS assigned_name
      FROM tasks t
      LEFT JOIN guests g ON g.id = t.assigned_to_guest_id
      LEFT JOIN users  u ON u.id = t.assigned_to_user_id
      WHERE t.event_id = ?
    ''', [eventId]);
    return rows.map((r) => TaskModel.fromMap(r)).toList();
  }

  static Future<void> updateTaskDone(int taskId, bool isDone) async {
    final db = await database;
    await db.update('tasks', {'is_done': isDone ? 1 : 0}, where: 'id = ?', whereArgs: [taskId]);
  }

  static Future<void> updateTaskAssignment(int taskId, {int? guestId, int? userId}) async {
    final db = await database;
    await db.update('tasks',
        {'assigned_to_guest_id': guestId, 'assigned_to_user_id': userId},
        where: 'id = ?', whereArgs: [taskId]);
  }

  static Future<void> deleteTask(int taskId) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }
}
