import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/revision.dart';
import '../services/media_service.dart';
import 'database_helper.dart';

class RevisionRepository {
  // Ordenadas de la más reciente a la más antigua.
  Future<List<Revision>> obtenerPorEquipo(int equipoId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query(
        'revisiones',
        where: 'equipo_id = ?',
        whereArgs: [equipoId],
        orderBy: 'fecha DESC',
      );
      return maps.map(Revision.fromMap).toList();
    } on DatabaseException catch (e, st) {
      debugPrint('Error al obtener revisiones: $e\n$st');
      rethrow;
    }
  }

  // Para la lista: revisiones de todos los equipos agrupadas por equipoId (más reciente primero).
  Future<Map<int, List<Revision>>> obtenerAgrupadasPorEquipo() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('revisiones', orderBy: 'fecha DESC');
      final grupos = <int, List<Revision>>{};
      for (final m in maps) {
        final r = Revision.fromMap(m);
        (grupos[r.equipoId] ??= []).add(r);
      }
      return grupos;
    } on DatabaseException catch (e, st) {
      debugPrint('Error al agrupar revisiones: $e\n$st');
      rethrow;
    }
  }

  Future<int> insertar(Revision revision) async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.insert('revisiones', revision.toMap());
    } on DatabaseException catch (e, st) {
      debugPrint('Error al insertar revisión: $e\n$st');
      rethrow;
    }
  }

  // También borra su foto.
  Future<void> eliminar(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('revisiones', columns: ['foto_path'], where: 'id = ?', whereArgs: [id]);
      final foto = maps.isEmpty ? null : maps.first['foto_path'] as String?;

      await db.delete('revisiones', where: 'id = ?', whereArgs: [id]);

      try {
        await MediaService().eliminarFoto(foto);
      } catch (e) {
        debugPrint('No se pudo borrar la foto $foto: $e');
      }
    } on DatabaseException catch (e, st) {
      debugPrint('Error al eliminar revisión $id: $e\n$st');
      rethrow;
    }
  }
}
