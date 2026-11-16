import 'package:material_ui/material_ui.dart';

import '../../routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.alVolver});

  // Se llama al regresar de la pantalla abierta (p. ej. para recargar la lista).
  final VoidCallback? alVolver;

  Future<void> _ir(BuildContext context, String ruta) async {
    final nav = Navigator.of(context);
    nav.pop(); // cierra el drawer
    await nav.pushNamed(ruta);
    alVolver?.call();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: tema.colorScheme.primaryContainer),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text('Mis Equipos', style: tema.textTheme.headlineSmall),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Mis equipos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.popUntil(context, (r) => r.isFirst);
            },
          ),
          ListTile(
            leading: const Icon(Icons.pending_actions),
            title: const Text('Revisiones pendientes'),
            onTap: () => _ir(context, Rutas.pendientes),
          ),
          ListTile(
            leading: const Icon(Icons.hourglass_bottom),
            title: const Text('Vida útil de referencia'),
            onTap: () => _ir(context, Rutas.vidaUtil),
          ),
        ],
      ),
    );
  }
}
