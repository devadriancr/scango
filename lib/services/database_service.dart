import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  late Database _database;

  Future<void> initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'materials.db');
    _database = await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE materials (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      supplier VARCHAR NULL,
      serial VARCHAR NULL,
      part_no VARCHAR NULL,
      part_qty INTEGER NOT NULL,
      container_id INTEGER NULL,
      no_order VARCHAR NULL,
      status BOOLEAN DEFAULT 1,
      type TEXT NOT NULL, -- 'entry' o 'exit'
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''');
  }

  // Cargar registros por tipo (entry o exit), filtrados por container_id y status = true
  Future<List<Map<String, dynamic>>> loadMaterialEntries(
      int containerId, String type) async {
    return await _database.query(
      'materials',
      where: 'container_id = ? AND type = ? AND status = 1',
      whereArgs: [containerId, 'entry'],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> loadMaterialExit(
      int containerId, String type) async {
    return await _database.query(
      'materials',
      where: 'status = 1',
      whereArgs: [type],
      orderBy: 'created_at DESC',
    );
  }

  // Verificar si el material ya está registrado para un tipo específico
  Future<bool> materialRegisteredInEntries(int containerId, String partNo,
      int partQty, String? supplier, String? serial, String type) async {
    final result = await _database.query(
      'materials',
      where:
          'container_id = ? AND part_no = ? AND part_qty = ? AND supplier = ? AND serial = ? AND type = ? AND status = 1',
      whereArgs: [containerId, partNo, partQty, supplier, serial, type],
    );
    return result.isNotEmpty;
  }

  // Insertar nuevos datos en la base de datos
  Future<void> insertData({
    required int partQty,
    required String type,
    int? containerId,
    String? partNo,
    String? supplier,
    String? serial,
    String? noOrder,
  }) async {
    await _database.insert('materials', {
      'part_qty': partQty,
      'type': type,
      'container_id': containerId,
      'part_no': partNo,
      'supplier': supplier,
      'serial': serial,
      'no_order': noOrder,
    });
  }

  // Actualizar el estado del material
  Future<void> updateStatus(String partNo, int containerId, String type) async {
    await _database.update(
      'materials',
      {'status': 0}, // Cambiar status a 0 para marcar como no activo
      where: 'part_no = ? AND container_id = ? AND type = ?',
      whereArgs: [partNo, containerId, type],
    );
  }

  Future<void> closeDatabase() async {
    await _database.close();
  }
}
