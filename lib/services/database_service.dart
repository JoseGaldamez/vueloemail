import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/email_message.dart';

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
      version: 3, // v3: añade columna userEmail para soporte multi-usuario
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop and recreate to ensure clean multi-user schema
        await db.execute('DROP TABLE IF EXISTS emails');
        await _onCreate(db, newVersion);
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
  }

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
