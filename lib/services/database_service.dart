import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  late Database _database;

  // Inicializar la base de datos
  Future<void> initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'materials.db');
    _database = await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // Crear la tabla de materiales si no existe
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

  // Obtener todas las entradas activas por contenedor y tipo
  Future<List<Map<String, dynamic>>> getActiveMaterialEntries(
      int containerId) async {
    try {
      return await _database.query(
        'materials',
        where: 'container_id = ? AND type = "entry" AND status = 1',
        whereArgs: [containerId],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error loading material entries: $e');
      return []; // Devuelve lista vacía en caso de error
    }
  }

  // Obtener todas las salidas activas por contenedor y tipo
  Future<List<Map<String, dynamic>>> getActiveMaterialExits() async {
    try {
      return await _database.query(
        'materials',
        where: 'type = "exit" AND status = 1',
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error loading material exits: $e');
      return [];
    }
  }

  // Verificar si un material ya está registrado como entrada
  Future<bool> isMaterialRegistered(int containerId, String partNo, int partQty,
      String? supplier, String? serial) async {
    try {
      final result = await _database.query(
        'materials',
        where:
            'container_id = ? AND part_no = ? AND part_qty = ? AND supplier = ? AND serial = ? AND type = "entry" AND status = 1',
        whereArgs: [containerId, partNo, partQty, supplier, serial],
      );
      return result.isNotEmpty; // Devuelve true si ya está registrado
    } catch (e) {
      print('Error checking if material is registered: $e');
      return false; // Devuelve false en caso de error
    }
  }

  // Verificar si un material ya está registrado como salida
  Future<bool> isMaterialExitRegistered({
    required String supplier,
    required String serial,
    required String partNo,
    required int partQty,
    String? noOrder, // Hacer que noOrder sea opcional
  }) async {
    try {
      // Construir la cláusula WHERE dinámicamente
      String whereClause =
          'supplier = ? AND serial = ? AND part_no = ? AND part_qty = ? AND type = "exit" AND status = 1';
      List<dynamic> whereArgs = [supplier, serial, partNo, partQty];

      if (noOrder != null) {
        whereClause += ' AND (no_order = ? OR no_order IS NULL)';
        whereArgs.add(noOrder);
      } else {
        whereClause +=
            ' AND no_order IS NULL'; // Comparar con NULL si noOrder no se proporciona
      }

      final result = await _database.query(
        'materials',
        where: whereClause,
        whereArgs: whereArgs,
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if material exit is registered: $e');
      return false;
    }
  }

  // Agregar una nueva entrada de material
  Future<void> addMaterialEntry({
    String? supplier,
    String? serial,
    String? partNo,
    required int partQty,
    int? containerId,
    String? noOrder,
  }) async {
    try {
      await _database.insert('materials', {
        'supplier': supplier,
        'serial': serial,
        'part_no': partNo,
        'part_qty': partQty,
        'type': 'entry',
        'container_id': containerId,
        'no_order': noOrder,
      });
    } catch (e) {
      print('Error adding material entry: $e');
    }
  }

  // Agregar una nueva salida de material
  Future<void> addMaterialExit({
    String? supplier,
    String? serial,
    String? partNo,
    required int partQty,
    String? noOrder,
  }) async {
    try {
      await _database.insert('materials', {
        'supplier': supplier,
        'serial': serial,
        'part_no': partNo,
        'part_qty': partQty,
        'type': 'exit',
        'no_order': noOrder,
      });
    } catch (e) {
      print('Error adding material exit: $e');
    }
  }

  // Desactivar una entrada de material
  Future<void> deactivateMaterialEntry(String partNo, int containerId) async {
    try {
      await _database.update(
        'materials',
        {'status': 0}, // Cambiar status a 0 para marcar como inactivo
        where: 'part_no = ? AND container_id = ? AND type = "entry"',
        whereArgs: [partNo, containerId],
      );
    } catch (e) {
      print('Error deactivating material entry: $e');
    }
  }

  Future<void> updateStatus(String partNo, int containerId) async {
    await _database.update('materials', {'status': 'scanned'},
        where: 'part_no = ? AND container_id = ? AND type = "entry"',
        whereArgs: [partNo, containerId]);
  }

  Future<void> updateMaterialExitStatus(int id, bool status) async {
    await _database.update(
      'material_exits',
      {'status': status ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cerrar la conexión con la base de datos
  Future<void> closeConnection() async {
    await _database.close();
  }
}
