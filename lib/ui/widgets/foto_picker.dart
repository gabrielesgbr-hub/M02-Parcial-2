import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../services/media_service.dart';

// Vista previa + botones Cámara / Galería / Quitar.
// No borra la foto anterior: eso lo decide el formulario al guardar.
class FotoPicker extends StatefulWidget {
  const FotoPicker({
    super.key,
    required this.fotoPath,
    required this.onCambio,
    this.iconoVacio = Icons.photo_camera,
  });

  final String? fotoPath;
  final ValueChanged<String?> onCambio;
  final IconData iconoVacio;

  @override
  State<FotoPicker> createState() => _FotoPickerState();
}

class _FotoPickerState extends State<FotoPicker> {
  final _media = MediaService();
  bool _cargando = false;

  Future<void> _elegir(Future<String?> Function() obtener) async {
    setState(() => _cargando = true);
    try {
      final ruta = await obtener();
      if (ruta != null) widget.onCambio(ruta);
    } on PlatformException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la foto')),
        );
      }
    } on FileSystemException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la foto')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.fotoPath;
    final tieneFoto = path != null && File(path).existsSync();
    final vacio = Center(child: Icon(widget.iconoVacio, size: 48));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 180,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : tieneFoto
                  ? Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => vacio,
                    )
                  : vacio,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _cargando ? null : () => _elegir(_media.tomarFoto),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Cámara'),
            ),
            OutlinedButton.icon(
              onPressed:
                  _cargando ? null : () => _elegir(_media.elegirDeGaleria),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galería'),
            ),
            if (tieneFoto)
              TextButton.icon(
                onPressed: _cargando ? null : () => widget.onCambio(null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Quitar'),
              ),
          ],
        ),
      ],
    );
  }
}
