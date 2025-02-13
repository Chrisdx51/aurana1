import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'horoscope.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE horoscopes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        zodiac_sign TEXT,
        date TEXT,
        horoscope TEXT
      )
    ''');
  }

  Future<int> insertHoroscope(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('horoscopes', row);
  }

  Future<List<Map<String, dynamic>>> queryAllHoroscopes() async {
    Database db = await database;
    return await db.query('horoscopes');
  }
}