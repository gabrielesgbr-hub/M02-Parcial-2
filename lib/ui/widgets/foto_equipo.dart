import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../models/equipo.dart';

// Foto del equipo envuelta en Hero; se usa igual en la lista y en el detalle para que el tag coincida.
class FotoEquipo extends StatelessWidget {
  const FotoEquipo({super.key, required this.equipo, this.tamano = 56});

  final Equipo equipo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final path = equipo.fotoPath;
    return Hero(
      tag: 'equipo-foto-${equipo.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: tamano,
          height: tamano,
          child: path != null && File(path).existsSync()
              ? Image.file(File(path), fit: BoxFit.cover)
              : ColoredBox(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(equipo.tipo.icono, size: tamano * 0.5),
                ),
        ),
      ),
    );
  }
}
