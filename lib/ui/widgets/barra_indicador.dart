import 'package:material_ui/material_ui.dart';

import '../../logic/estado_equipo.dart';
import 'alerta_chip.dart';

// Barra de color según el nivel; `compacta` para la tarjeta de la lista.
class BarraIndicador extends StatelessWidget {
  const BarraIndicador({
    super.key,
    required this.indicador,
    this.compacta = false,
  });

  final Indicador indicador;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final color = colorNivel(indicador.nivel);
    final estilo = compacta
        ? Theme.of(context).textTheme.bodySmall
        : const TextStyle(fontWeight: FontWeight.w600);
    return Padding(
      padding: EdgeInsets.only(top: compacta ? 4 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap: si no cabe en una línea, el texto baja en vez de desbordarse.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            children: [
              Text(indicador.etiqueta, style: estilo),
              Text(indicador.texto, style: compacta ? estilo : null),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: indicador.valor,
            minHeight: compacta ? 5 : 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
