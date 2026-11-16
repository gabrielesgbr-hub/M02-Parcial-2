import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/accesorio.dart';
import 'database_helper.dart';

class AccesorioRepository {
  Future<List<Accesorio>> obtenerPorEquipo(int equipoId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('accesorios', where: 'equipo_id = ?', whereArgs: [equipoId]);
      return maps.map(Accesorio.fromMap).toList();
    } on DatabaseException catch (e, st) {
      debugPrint('Error al obtener accesorios: $e\n$st');
      rethrow;
    }
  }

  Future<int> insertar(Accesorio accesorio) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.insert('accesorios', accesorio.toMap());
    } on DatabaseException catch (e, st) {
      debugPrint('Error al insertar accesorio: $e\n$st');
      rethrow;
    }
  }

  Future<void> actualizar(Accesorio accesorio) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('accesorios', accesorio.toMap(), where: 'id = ?', whereArgs: [accesorio.id]);
    } on DatabaseException catch (e, st) {
      debugPrint('Error al actualizar accesorio: $e\n$st');
      rethrow;
    }
  }

  Future<void> eliminar(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('accesorios', where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e, st) {
      debugPrint('Error al eliminar accesorio $id: $e\n$st');
      rethrow;
    }
  }
}
