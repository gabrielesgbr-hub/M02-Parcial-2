import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// Singleton: una sola conexión a la BD para toda la app.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  // Se guarda el Future para que llamadas simultáneas compartan la misma apertura.
  static Future<Database>? _database;

  DatabaseHelper._init();

  Future<Database> get database {
    return _database ??= _initDB('equipos.db').catchError((Object e, StackTrace st) {
      _database = null; // permite reintentar si falló al abrir
      Error.throwWithStackTrace(e, st);
    });
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE equipos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        nombre TEXT NOT NULL,
        marca TEXT,
        modelo TEXT,
        numero_serie TEXT,
        procesador TEXT,
        ram_gb INTEGER,
        almacenamiento_gb INTEGER,
        fecha_compra TEXT NOT NULL,
        foto_path TEXT,
        notas TEXT,
        creado_en TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE revisiones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipo_id INTEGER NOT NULL REFERENCES equipos(id) ON DELETE CASCADE,
        fecha TEXT NOT NULL,
        limpieza INTEGER NOT NULL,
        almacenamiento_pct INTEGER,
        bateria_pct INTEGER,
        sobrecalentamiento INTEGER,
        mantenimiento INTEGER,
        observaciones TEXT,
        foto_path TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE accesorios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipo_id INTEGER NOT NULL REFERENCES equipos(id) ON DELETE CASCADE,
        tipo TEXT NOT NULL,
        descripcion TEXT,
        fecha_compra TEXT,
        estado TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migraciones futuras.
  }
}
