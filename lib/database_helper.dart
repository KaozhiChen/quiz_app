import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'leaderboard.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE leaderboard (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            category TEXT NOT NULL,
            score INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertScore(String username, String category, int score) async {
    final db = await database;
    await db.insert('leaderboard', {
      'username': username,
      'category': category,
      'score': score,
    });
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(String category) async {
    final db = await database;
    return await db.query(
      'leaderboard',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'score DESC',
      limit: 5,
    );
  }
}
