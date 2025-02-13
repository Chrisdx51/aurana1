import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AuraDatabaseHelper {
  static final AuraDatabaseHelper _instance = AuraDatabaseHelper._internal();
  static Database? _database;

  factory AuraDatabaseHelper() => _instance;

  AuraDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    final directory = await getDatabasesPath();
    final path = join(directory, 'aura_database.db');

    return await openDatabase(
      path,
      version: 2, // Increment version for schema changes
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE aura_details (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT,
            auraMeaning TEXT,
            auraColor TEXT,
            timestamp TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE aura_details ADD COLUMN auraColor TEXT');
          await db.execute('ALTER TABLE aura_details ADD COLUMN timestamp TEXT');
        }
      },
    );
  }

  Future<void> saveAuraDetail(String imagePath, String auraMeaning, String auraColor, String timestamp) async {
    final db = await database;
    await db.insert(
      'aura_details',
      {
        'imagePath': imagePath,
        'auraMeaning': auraMeaning,
        'auraColor': auraColor,
        'timestamp': timestamp,
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchAuraDetails() async {
    final db = await database;
    return await db.query('aura_details', orderBy: 'id DESC');
  }

  Future<void> deleteAuraDetail(int id) async {
    final db = await database;
    await db.delete('aura_details', where: 'id = ?', whereArgs: [id]);
  }
}
