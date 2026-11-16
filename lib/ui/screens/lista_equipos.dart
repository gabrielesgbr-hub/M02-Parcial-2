import 'package:material_ui/material_ui.dart';

import '../../data/equipo_repository.dart';
import '../../data/revision_repository.dart';
import '../../models/equipo.dart';
import '../../models/revision.dart';
import '../../routes.dart';
import '../widgets/app_drawer.dart';
import '../widgets/equipo_card.dart';

typedef DatosEquipos = (List<Equipo>, Map<int, List<Revision>>);

// Carga equipos y sus revisiones en un solo Future (también lo usa Pendientes).
Future<DatosEquipos> cargarDatosEquipos() async {
  final equipos = await EquipoRepository().obtenerTodos();
  final revisiones = await RevisionRepository().obtenerAgrupadasPorEquipo();
  return (equipos, revisiones);
}

// Inicio: lista de equipos con Drawer.
class PantallaListaEquipos extends StatefulWidget {
  const PantallaListaEquipos({super.key});

  @override
  State<PantallaListaEquipos> createState() => _PantallaListaEquiposState();
}

class _PantallaListaEquiposState extends State<PantallaListaEquipos> {
  late Future<DatosEquipos> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = cargarDatosEquipos();
  }

  void _recargar() => setState(() => _futuro = cargarDatosEquipos());

  Future<void> _agregar() async {
    final guardo = await Navigator.pushNamed(context, Rutas.formEquipo);
    if (guardo == true) _recargar();
  }

  Future<void> _abrirDetalle(Equipo equipo) async {
    await Navigator.pushNamed(context, Rutas.detalle, arguments: equipo);
    _recargar(); // en el detalle pudieron editar o borrar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis equipos')),
      drawer: AppDrawer(alVolver: _recargar),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregar,
        tooltip: 'Agregar equipo',
        child: const Icon(Icons.add),
      ),
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
              if (equipos.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aún no registras equipos. Toca + para agregar uno.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                itemCount: equipos.length,
                itemBuilder: (context, i) {
                  final e = equipos[i];
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
