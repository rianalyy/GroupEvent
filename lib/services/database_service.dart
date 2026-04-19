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
import '../models/chat_message_model.dart';

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
    return await openDatabase(path, version: 10, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE, password TEXT NOT NULL)');
    await db.execute('CREATE TABLE session (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL)');
    await db.execute('''CREATE TABLE events (
      id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, date TEXT NOT NULL,
      location TEXT NOT NULL DEFAULT '', latitude REAL, longitude REAL,
      participants INTEGER NOT NULL DEFAULT 1, budget REAL NOT NULL DEFAULT 0,
      description TEXT DEFAULT '', creator_id INTEGER, invite_code TEXT UNIQUE,
      FOREIGN KEY (creator_id) REFERENCES users(id))''');
    await db.execute('''CREATE TABLE guests (
      id INTEGER PRIMARY KEY AUTOINCREMENT, event_id INTEGER NOT NULL, name TEXT NOT NULL,
      email TEXT, rsvp_status TEXT NOT NULL DEFAULT 'pending', user_id INTEGER,
      FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id))''');
    await db.execute('''CREATE TABLE tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT, event_id INTEGER NOT NULL, title TEXT NOT NULL,
      is_done INTEGER NOT NULL DEFAULT 0, assigned_to_guest_id INTEGER, assigned_to_user_id INTEGER,
      FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE)''');
    await db.execute('''CREATE TABLE chat_messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT, event_id INTEGER NOT NULL, user_id INTEGER NOT NULL,
      user_name TEXT NOT NULL, message TEXT NOT NULL, sent_at TEXT NOT NULL,
      FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE)''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 10) {
      for (final t in ['chat_messages', 'tasks', 'guests', 'events', 'session', 'users']) {
        await db.execute('DROP TABLE IF EXISTS $t');
      }
      await _onCreate(db, newVersion);
    }
  }

  static String _hash(String p) => sha256.convert(utf8.encode(p)).toString();

  static Future<UserModel?> register({required String name, required String email, required String password}) async {
    final db = await database;
    if ((await db.query('users', where: 'LOWER(email) = LOWER(?)', whereArgs: [email])).isNotEmpty) return null;
    final id = await db.insert('users', {'name': name.trim(), 'email': email.trim().toLowerCase(), 'password': _hash(password)});
    return UserModel(id: id, name: name.trim(), email: email.trim().toLowerCase(), password: _hash(password));
  }

  static Future<UserModel?> login({required String email, required String password}) async {
    final db = await database;
    final r = await db.query('users', where: 'LOWER(email) = LOWER(?) AND password = ?', whereArgs: [email.trim().toLowerCase(), _hash(password)]);
    return r.isEmpty ? null : UserModel.fromMap(r.first);
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final r = await db.query('users', where: 'LOWER(email) = LOWER(?)', whereArgs: [email.trim().toLowerCase()]);
    return r.isEmpty ? null : UserModel.fromMap(r.first);
  }

  static Future<void> saveSession(int userId) async {
    final db = await database;
    await db.delete('session');
    await db.insert('session', {'id': 1, 'user_id': userId});
  }

  static Future<UserModel?> getSessionUser() async {
    final db = await database;
    final s = await db.query('session', where: 'id = 1');
    if (s.isEmpty) return null;
    final u = await db.query('users', where: 'id = ?', whereArgs: [s.first['user_id']]);
    return u.isEmpty ? null : UserModel.fromMap(u.first);
  }

  static Future<void> clearSession() async => (await database).delete('session');

  static Future<int> insertEvent(EventModel e) async => (await database).insert('events', e.toMap());

  static Future<List<EventModel>> getEventsByUser(int userId) async {
    final r = await (await database).query('events', where: 'creator_id = ?', whereArgs: [userId], orderBy: 'id DESC');
    return r.map(EventModel.fromMap).toList();
  }

  static Future<List<EventModel>> getInvitedEvents(int userId) async {
    final r = await (await database).rawQuery('SELECT DISTINCT e.* FROM events e INNER JOIN guests g ON g.event_id = e.id WHERE g.user_id = ? AND e.creator_id != ?', [userId, userId]);
    return r.map(EventModel.fromMap).toList();
  }

  static Future<void> deleteEvent(int id) async => (await database).delete('events', where: 'id = ?', whereArgs: [id]);

  static Future<int> addGuest(GuestModel g) async => (await database).insert('guests', g.toMap());

  static Future<List<GuestModel>> getGuestsForEvent(int eventId) async {
    final r = await (await database).query('guests', where: 'event_id = ?', whereArgs: [eventId]);
    return r.map(GuestModel.fromMap).toList();
  }

  static Future<void> updateGuestRsvp(int guestId, RsvpStatus s) async =>
      (await database).update('guests', {'rsvp_status': s.name}, where: 'id = ?', whereArgs: [guestId]);

  static Future<void> deleteGuest(int id) async => (await database).delete('guests', where: 'id = ?', whereArgs: [id]);

  static Future<bool> isAlreadyInvited(String email, int eventId) async {
    final r = await (await database).query('guests', where: 'LOWER(email) = LOWER(?) AND event_id = ?', whereArgs: [email.trim().toLowerCase(), eventId]);
    return r.isNotEmpty;
  }

  static Future<int> insertTask(TaskModel t) async => (await database).insert('tasks', t.toMap());

  static Future<List<TaskModel>> getTasksForEvent(int eventId) async {
    final r = await (await database).rawQuery('SELECT t.*, COALESCE(g.name, u.name) AS assigned_name FROM tasks t LEFT JOIN guests g ON g.id = t.assigned_to_guest_id LEFT JOIN users u ON u.id = t.assigned_to_user_id WHERE t.event_id = ?', [eventId]);
    return r.map(TaskModel.fromMap).toList();
  }

  static Future<void> updateTaskDone(int id, bool done) async =>
      (await database).update('tasks', {'is_done': done ? 1 : 0}, where: 'id = ?', whereArgs: [id]);

  static Future<void> updateTaskAssignment(int id, {int? guestId, int? userId}) async =>
      (await database).update('tasks', {'assigned_to_guest_id': guestId, 'assigned_to_user_id': userId}, where: 'id = ?', whereArgs: [id]);

  static Future<void> deleteTask(int id) async => (await database).delete('tasks', where: 'id = ?', whereArgs: [id]);

  static Future<int> insertMessage(ChatMessageModel m) async => (await database).insert('chat_messages', m.toMap());

  static Future<List<ChatMessageModel>> getMessages(int eventId) async {
    final r = await (await database).query('chat_messages', where: 'event_id = ?', whereArgs: [eventId], orderBy: 'sent_at ASC');
    return r.map(ChatMessageModel.fromMap).toList();
  }

  static Future<void> deleteMessage(int id) async => (await database).delete('chat_messages', where: 'id = ?', whereArgs: [id]);
}
