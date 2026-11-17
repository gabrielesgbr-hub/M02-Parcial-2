import 'package:material_ui/material_ui.dart';

import '../../logic/estado_equipo.dart';
import '../../models/equipo.dart';
import '../../models/revision.dart';
import 'alerta_chip.dart';
import 'barra_indicador.dart';
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
    final dias = diasParaRevision(revisiones);
    final detalle = [
      equipo.tipo.etiqueta,
      equipo.marca,
      equipo.modelo,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: FotoEquipo(equipo: equipo),
        title: Text(equipo.nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detalle),
            BarraIndicador(
              indicador: indicadorMasPreocupante(
                indicadores(equipo, revisiones),
              ),
              compacta: true,
            ),
            if (dias == null)
              Text(
                'Revisión pendiente',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.error,
                ),
              )
            else
              // Tono neutro: solo informa, no alerta.
              Text(
                switch (dias) {
                  0 => 'Próxima revisión hoy',
                  1 => 'Próxima revisión en 1 día',
                  _ => 'Próxima revisión en $dias días',
                },
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: Icon(Icons.circle, size: 16, color: colorNivel(nivel)),
      ),
    );
  }
}
