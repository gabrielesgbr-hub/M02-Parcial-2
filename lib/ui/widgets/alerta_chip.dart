import 'package:material_ui/material_ui.dart';

import '../../logic/estado_equipo.dart';

// Verde = ok, ámbar = advertencia, rojo = crítica.
Color colorNivel(NivelAlerta nivel) => switch (nivel) {
      NivelAlerta.ok => Colors.green,
      NivelAlerta.advertencia => Colors.amber.shade800,
      NivelAlerta.critica => Colors.red,
    };

class AlertaChip extends StatelessWidget {
  const AlertaChip({super.key, required this.alerta});

  final Alerta alerta;

  @override
  Widget build(BuildContext context) {
    final color = colorNivel(alerta.nivel);
    return Chip(
      avatar: Icon(Icons.circle, size: 12, color: color),
      label: Text(alerta.mensaje),
      side: BorderSide(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
