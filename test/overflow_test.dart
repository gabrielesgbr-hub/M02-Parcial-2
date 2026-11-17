import 'package:flutter_test/flutter_test.dart';
import 'package:m02_parcial2/models/equipo.dart';
import 'package:m02_parcial2/models/revision.dart';
import 'package:m02_parcial2/models/tipo_equipo.dart';
import 'package:m02_parcial2/ui/widgets/dialogo_accesorio.dart';
import 'package:m02_parcial2/ui/widgets/equipo_card.dart';
import 'package:material_ui/material_ui.dart';

// Teléfono angosto (320dp) con texto agrandado: un overflow lanza excepción y falla el test.
Future<void> pintar(WidgetTester tester, Widget hijo) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(1.3),
        ),
        child: Scaffold(body: hijo),
      ),
    ),
  );
}

final equipo = Equipo(
  id: 1,
  tipo: TipoEquipo.laptop,
  nombre: 'Laptop de trabajo con un nombre bastante largo',
  marca: 'Marca',
  modelo: 'Modelo muy largo X1 Carbon Gen 11',
  almacenamientoGb: 1024,
  fechaCompra: DateTime.now().subtract(const Duration(days: 400)),
  creadoEn: DateTime.now(),
);

void main() {
  testWidgets('la tarjeta con barra de almacenamiento no se desborda', (
    tester,
  ) async {
    final rev = Revision(
      equipoId: 1,
      fecha: DateTime.now(),
      limpieza: true,
      almacenamientoUsadoGb: 1000,
    );
    await pintar(
      tester,
      ListView(
        children: [
          EquipoCard(equipo: equipo, revisiones: [rev], onTap: () {}),
        ],
      ),
    );
    expect(find.textContaining('1000 de 1024 GB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el diálogo de accesorio no se desborda', (tester) async {
    await pintar(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => mostrarDialogoAccesorio(context, equipo: equipo),
          child: const Text('abrir'),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Regular'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
