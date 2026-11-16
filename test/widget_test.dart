import 'package:flutter_test/flutter_test.dart';

import 'package:m02_parcial2/main.dart';

void main() {
  // En pruebas no hay SQLite real: la lista debe mostrar su error controlado, no romperse.
  testWidgets('La app arranca y el Drawer muestra sus opciones', (tester) async {
    await tester.pumpWidget(const MisEquiposApp());
    await tester.pumpAndSettle();

    expect(find.text('Mis equipos'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Revisiones pendientes'), findsOneWidget);
    expect(find.text('Vida útil de referencia'), findsOneWidget);
  });
}
