import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/equipo.dart';
import '../services/media_service.dart';
import 'database_helper.dart';

// Los errores de BD se registran y se relanzan (rethrow) para que la UI los muestre.
class EquipoRepository {
  Future<List<Equipo>> obtenerTodos() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('equipos', orderBy: 'nombre COLLATE NOCASE');
      return maps.map(Equipo.fromMap).toList();
    } on DatabaseException catch (e, st) {
      debugPrint('Error al obtener equipos: $e\n$st');
      rethrow;
    }
  }

  Future<Equipo?> obtenerPorId(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('equipos', where: 'id = ?', whereArgs: [id]);
      return maps.isEmpty ? null : Equipo.fromMap(maps.first);
    } on DatabaseException catch (e, st) {
      debugPrint('Error al obtener equipo $id: $e\n$st');
      rethrow;
    }
  }

  // Devuelve el id generado.
  Future<int> insertar(Equipo equipo) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.insert('equipos', equipo.toMap());
    } on DatabaseException catch (e, st) {
      debugPrint('Error al insertar equipo: $e\n$st');
      rethrow;
    }
  }

  Future<void> actualizar(Equipo equipo) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update('equipos', equipo.toMap(), where: 'id = ?', whereArgs: [equipo.id]);
    } on DatabaseException catch (e, st) {
      debugPrint('Error al actualizar equipo: $e\n$st');
      rethrow;
    }
  }

  // Borra en cascada revisiones y accesorios, y las fotos guardadas.
  Future<void> eliminar(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final equipo = await db.query('equipos', columns: ['foto_path'], where: 'id = ?', whereArgs: [id]);
      final revs = await db.query('revisiones', columns: ['foto_path'], where: 'equipo_id = ?', whereArgs: [id]);
      final fotos = [...equipo, ...revs].map((m) => m['foto_path'] as String?);

      await db.delete('equipos', where: 'id = ?', whereArgs: [id]);

      // Un fallo de archivo no debe romper el borrado.
      for (final path in fotos) {
        try {
          await MediaService().eliminarFoto(path);
        } catch (e) {
          debugPrint('No se pudo borrar la foto $path: $e');
        }
      }
    } on DatabaseException catch (e, st) {
      debugPrint('Error al eliminar equipo $id: $e\n$st');
      rethrow;
    }
  }
}
