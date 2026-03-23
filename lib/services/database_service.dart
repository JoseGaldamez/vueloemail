import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/email_message.dart';
import '../models/chat_message.dart';
import '../models/roster_contact.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vuelo_email_cache.db');

    return await openDatabase(
      path,
      version: 4, // v4: añade soporte para chat y contactos
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS emails');
          await _onCreate(db, newVersion);
        } else if (oldVersion == 3) {
          // Si venimos de v3, solo necesitamos crear las nuevas tablas
          await _createChatTables(db);
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE emails (
        id TEXT,
        messageId TEXT,
        inReplyTo TEXT,
        referencesList TEXT,
        boxName TEXT,
        userEmail TEXT,
        subject TEXT,
        "from" TEXT,
        "to" TEXT,
        timestamp TEXT,
        body TEXT,
        htmlBody TEXT,
        isRead INTEGER,
        PRIMARY KEY (id, boxName, userEmail)
      )
    ''');
    await _createChatTables(db);
  }

  Future<void> _createChatTables(Database db) async {
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        fromJid TEXT,
        toJid TEXT,
        body TEXT,
        timestamp TEXT,
        isMe INTEGER,
        isRead INTEGER,
        userEmail TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE contacts (
        jid TEXT,
        name TEXT,
        userEmail TEXT,
        PRIMARY KEY (jid, userEmail)
      )
    ''');
  }

  // ── Chat Persistence ──────────────────────────────────────────────────────

  Future<void> insertChatMessage(ChatMessage msg, String userEmail) async {
    final db = await database;
    final map = msg.toMap();
    map['userEmail'] = userEmail;
    await db.insert('chat_messages', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ChatMessage>> getChatMessages(String userEmail) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'userEmail = ?',
      whereArgs: [userEmail],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ChatMessage.fromMap(maps[i]));
  }

  Future<void> markChatAsRead(String otherJid, String userEmail) async {
    final db = await database;
    await db.update(
      'chat_messages',
      {'isRead': 1},
      where: 'userEmail = ? AND (fromJid = ? OR toJid = ?) AND isMe = 0',
      whereArgs: [userEmail, otherJid, otherJid],
    );
  }

  // ── Contact Persistence ───────────────────────────────────────────────────

  Future<void> insertContact(RosterContact contact, String userEmail) async {
    final db = await database;
    final map = contact.toMap();
    map['userEmail'] = userEmail;
    await db.insert('contacts', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<RosterContact>> getContacts(String userEmail) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contacts',
      where: 'userEmail = ?',
      whereArgs: [userEmail],
    );
    return List.generate(maps.length, (i) => RosterContact.fromMap(maps[i]));
  }

  // ── Email Persistence ──────────────────────────────────────────────────────

  Future<void> insertEmails(
    List<EmailMessage> emails,
    String boxName,
    String userEmail,
  ) async {
    final db = await database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var email in emails) {
        final map = email.toJson();
        map['referencesList'] = map['references'];
        map.remove('references');

        map['boxName'] = boxName;
        map['userEmail'] = userEmail;
        map['isRead'] = email.isRead ? 1 : 0;
        batch.insert('emails', map, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<EmailMessage>> getEmails(String boxName, String userEmail) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'emails',
      where: 'boxName = ? AND userEmail = ?',
      whereArgs: [boxName, userEmail],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      final map = Map<String, dynamic>.from(maps[i]);
      map['isRead'] = map['isRead'] == 1;

      map['references'] = map['referencesList'];
      map.remove('referencesList');
      map.remove('userEmail');

      return EmailMessage.fromJson(map);
    });
  }

  Future<void> markThreadsAsRead(List<String> ids, String userEmail) async {
    if (ids.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (var id in ids) {
      batch.update(
        'emails',
        {'isRead': 1},
        where: 'id = ? AND userEmail = ?',
        whereArgs: [id, userEmail],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Elimina todos los correos en caché de un usuario específico.
  /// Útil al hacer logout para no dejar datos residuales.
  Future<void> clearUserCache(String userEmail) async {
    final db = await database;
    await db.delete('emails', where: 'userEmail = ?', whereArgs: [userEmail]);
  }
}
