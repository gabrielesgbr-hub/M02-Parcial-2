import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Fotos con image_picker. Se copian al directorio de la app y se borra el temporal.
class MediaService {
  final ImagePicker _picker = ImagePicker();

  // Devuelven la ruta permanente, o null si el usuario canceló.
  Future<String?> tomarFoto() => _capturar(ImageSource.camera);

  Future<String?> elegirDeGaleria() => _capturar(ImageSource.gallery);

  Future<String?> _capturar(ImageSource fuente) async {
    try {
      final xfile = await _picker.pickImage(
        source: fuente,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (xfile == null) return null;

      final base = await getApplicationDocumentsDirectory();
      final carpeta = Directory(p.join(base.path, 'fotos'));
      if (!await carpeta.exists()) await carpeta.create(recursive: true);

      final destino = p.join(
        carpeta.path,
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(xfile.path).copy(destino);

      // El temporal queda en caché; si no se puede borrar no importa.
      try {
        await File(xfile.path).delete();
      } on FileSystemException catch (e) {
        debugPrint('No se borró el temporal: $e');
      }
      return destino;
    } on PlatformException catch (e, st) {
      debugPrint('Error al obtener la foto: $e\n$st');
      rethrow;
    }
  }

  // No falla si la ruta es null o el archivo ya no existe.
  Future<void> eliminarFoto(String? path) async {
    if (path == null) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } on FileSystemException catch (e) {
      debugPrint('No se pudo eliminar la foto: $e');
    }
  }
}
