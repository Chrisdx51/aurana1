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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE aura_details (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT,
            auraMeaning TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveAuraDetail(String imagePath, String auraMeaning) async {
    final db = await database;
    await db.insert(
      'aura_details',
      {'imagePath': imagePath, 'auraMeaning': auraMeaning},
    );
  }

  Future<List<Map<String, dynamic>>> fetchAuraDetails() async {
    final db = await database;
    return await db.query('aura_details');
  }
}
