import 'package:material_ui/material_ui.dart';

import 'routes.dart';
import 'ui/screens/detalle_equipo.dart';
import 'ui/screens/form_equipo.dart';
import 'ui/screens/form_revision.dart';
import 'ui/screens/lista_equipos.dart';
import 'ui/screens/pendientes.dart';
import 'ui/screens/vida_util.dart';

void main() {
  runApp(const MisEquiposApp());
}

class MisEquiposApp extends StatelessWidget {
  const MisEquiposApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis Equipos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: Rutas.inicio,
      routes: {
        Rutas.inicio: (_) => const PantallaListaEquipos(),
        Rutas.detalle: (_) => const PantallaDetalleEquipo(),
        Rutas.formEquipo: (_) => const PantallaFormEquipo(),
        Rutas.formRevision: (_) => const PantallaFormRevision(),
        Rutas.pendientes: (_) => const PantallaPendientes(),
        Rutas.vidaUtil: (_) => const PantallaVidaUtil(),
      },
    );
  }
}
