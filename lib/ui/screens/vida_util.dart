import 'package:material_ui/material_ui.dart';

import '../../models/tipo_equipo.dart';

// Tabla informativa de vida útil por tipo.
class PantallaVidaUtil extends StatefulWidget {
  const PantallaVidaUtil({super.key});

  @override
  State<PantallaVidaUtil> createState() => _PantallaVidaUtilState();
}

class _PantallaVidaUtilState extends State<PantallaVidaUtil> {
  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(title: const Text('Vida útil de referencia')),
      // SafeArea: que la barra de navegación de Android no tape la última fila.
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Tiempo estimado de uso antes de considerar reemplazar cada elemento.',
            ),
            const SizedBox(height: 16),
            Text('Equipos', style: estilo),
            for (final t in TipoEquipo.values)
              ListTile(
                leading: Icon(t.icono),
                title: Text(t.etiqueta),
                trailing: Text('${t.vidaUtilMeses} meses'),
              ),
            const SizedBox(height: 16),
            Text('Accesorios', style: estilo),
            for (final a in TipoAccesorio.values)
              ListTile(
                leading: const Icon(Icons.cable),
                title: Text(a.etiqueta),
                trailing: Text('${a.vidaUtilMeses} meses'),
              ),
          ],
        ),
      ),
    );
  }
}
