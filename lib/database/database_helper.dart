import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/sighting.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Singleton pattern - like a static class in C#
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ges_field_log.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Like CREATE TABLE in SQL Server
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sightings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        localId TEXT NOT NULL,
        species TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        animalCount INTEGER NOT NULL,
        photoPath TEXT,
        notes TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // INSERT
  Future<int> insertSighting(Sighting sighting) async {
    final db = await instance.database;
    return await db.insert('sightings', sighting.toMap());
  }

  // SELECT all - like SELECT * FROM sightings ORDER BY createdAt DESC
  Future<List<Sighting>> getAllSightings() async {
    final db = await instance.database;
    final result = await db.query(
      'sightings',
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Sighting.fromMap(map)).toList();
  }

  // SELECT unsynced - like SELECT * FROM sightings WHERE isSynced = 0
  Future<List<Sighting>> getUnsyncedSightings() async {
    final db = await instance.database;
    final result = await db.query(
      'sightings',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
    return result.map((map) => Sighting.fromMap(map)).toList();
  }

  // UPDATE isSynced flag after successful API sync
  Future<int> markAsSynced(int id) async {
    final db = await instance.database;
    return await db.update(
      'sightings',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE
  Future<int> deleteSighting(int id) async {
    final db = await instance.database;
    return await db.delete(
      'sightings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Count unsynced records
  Future<int> getUnsyncedCount() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sightings WHERE isSynced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}