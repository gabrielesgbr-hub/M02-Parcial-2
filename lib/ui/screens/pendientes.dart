import 'package:material_ui/material_ui.dart';

import '../../logic/estado_equipo.dart';
import '../../models/equipo.dart';
import '../../routes.dart';
import '../widgets/equipo_card.dart';
import 'lista_equipos.dart';

// Equipos con revisión pendiente (más de 7 días).
class PantallaPendientes extends StatefulWidget {
  const PantallaPendientes({super.key});

  @override
  State<PantallaPendientes> createState() => _PantallaPendientesState();
}

class _PantallaPendientesState extends State<PantallaPendientes> {
  late Future<DatosEquipos> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = cargarDatosEquipos();
  }

  void _recargar() => setState(() => _futuro = cargarDatosEquipos());

  Future<void> _abrirDetalle(Equipo equipo) async {
    await Navigator.pushNamed(context, Rutas.detalle, arguments: equipo);
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisiones pendientes')),
      body: FutureBuilder<DatosEquipos>(
        future: _futuro,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return const SizedBox.shrink();
            case ConnectionState.waiting:
            case ConnectionState.active:
              return const Center(child: CircularProgressIndicator());
            case ConnectionState.done:
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No se pudieron cargar los equipos.'),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _recargar, child: const Text('Reintentar')),
                    ],
                  ),
                );
              }
              final (equipos, revisiones) = snapshot.data!;
              final pendientes = equipos
                  .where((e) => revisionPendiente(revisiones[e.id] ?? const []))
                  .toList();
              if (pendientes.isEmpty) {
                return const Center(child: Text('Todos tus equipos están al día'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: pendientes.length,
                itemBuilder: (context, i) {
                  final e = pendientes[i];
                  return EquipoCard(
                    equipo: e,
                    revisiones: revisiones[e.id] ?? const [],
                    onTap: () => _abrirDetalle(e),
                  );
                },
              );
          }
        },
      ),
    );
  }
}
