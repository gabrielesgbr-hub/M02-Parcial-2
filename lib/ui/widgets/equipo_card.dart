import 'package:material_ui/material_ui.dart';

import '../../logic/estado_equipo.dart';
import '../../models/equipo.dart';
import '../../models/revision.dart';
import 'alerta_chip.dart';
import 'foto_equipo.dart';

class EquipoCard extends StatelessWidget {
  const EquipoCard({
    super.key,
    required this.equipo,
    required this.revisiones,
    required this.onTap,
  });

  final Equipo equipo;
  final List<Revision> revisiones;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nivel = nivelGeneral(calcularAlertas(equipo, revisiones));
    final detalle = [equipo.tipo.etiqueta, equipo.marca, equipo.modelo]
        .where((s) => s != null && s.isNotEmpty)
        .join(' · ');
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: FotoEquipo(equipo: equipo),
        title: Text(equipo.nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detalle),
            if (revisionPendiente(revisiones))
              Text(
                'Revisión pendiente',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
        trailing: Icon(Icons.circle, size: 16, color: colorNivel(nivel)),
      ),
    );
  }
}
