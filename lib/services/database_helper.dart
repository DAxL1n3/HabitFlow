import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart'; 
import '../models/habito_model.dart';
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init(); 

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habitos.db');
    return _database!;
  }
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habitos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        frecuencia TEXT NOT NULL,
        dias TEXT NOT NULL
      )
    ''');
  }

  Future<Habito> crearHabito(Habito habito) async {
    final db = await instance.database;
    final id = await db.insert('habitos', habito.toMap());
    return habito..id = id;
  }

  Future<List<Habito>> getHabitos() async {
    final db = await instance.database;
    final maps = await db.query('habitos', orderBy: 'id ASC');

    return List.generate(maps.length, (i) {
      return Habito(
        id: maps[i]['id'] as int,
        nombre: maps[i]['nombre'] as String,
        frecuencia: maps[i]['frecuencia'] as String,
        dias: maps[i]['dias'] as String,
      );
    });
  }

  Future<int> update(Habito habito) async {
    final db = await instance.database;
    return db.update(
      'habitos',
      habito.toMap(),
      where: 'id = ?', 
      whereArgs: [habito.id], 
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return db.delete(
      'habitos',
      where: 'id = ?', 
      whereArgs: [id], 
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}