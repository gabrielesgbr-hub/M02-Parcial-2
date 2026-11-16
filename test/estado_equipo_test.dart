import 'package:flutter_test/flutter_test.dart';
import 'package:m02_parcial2/logic/estado_equipo.dart';
import 'package:m02_parcial2/models/equipo.dart';
import 'package:m02_parcial2/models/revision.dart';
import 'package:m02_parcial2/models/tipo_equipo.dart';

final ahora = DateTime(2025, 6, 1);

Equipo equipo(TipoEquipo tipo, {DateTime? compra}) => Equipo(
      tipo: tipo,
      nombre: 'x',
      fechaCompra: compra ?? DateTime(2025, 5, 1),
      creadoEn: ahora,
    );

Revision rev({DateTime? fecha, int? alm, int? bat, bool? sobre, bool? mant}) => Revision(
      equipoId: 1,
      fecha: fecha ?? ahora,
      limpieza: true,
      almacenamientoPct: alm,
      bateriaPct: bat,
      sobrecalentamiento: sobre,
      mantenimiento: mant,
    );

DateTime haceDias(int d) => ahora.subtract(Duration(days: d));

void main() {
  group('vida útil', () {
    test('porcentaje y mínimo 0', () {
      expect(porcentajeVidaUtil(haceDias(305), 10, ahora: ahora), closeTo(305 / 304.4, 1e-9));
      expect(porcentajeVidaUtil(ahora.add(const Duration(days: 5)), 10, ahora: ahora), 0);
    });

    test('etapas y límites', () {
      expect(etapaVida(0.49), EtapaVida.nuevo);
      expect(etapaVida(0.5), EtapaVida.buenEstado);
      expect(etapaVida(0.79), EtapaVida.buenEstado);
      expect(etapaVida(0.8), EtapaVida.envejeciendo);
      expect(etapaVida(0.99), EtapaVida.envejeciendo);
      expect(etapaVida(1.0), EtapaVida.finVida);
    });
  });

  group('revisionPendiente', () {
    test('sin revisiones', () => expect(revisionPendiente([], ahora: ahora), isTrue));

    test('7 días no, 8 sí', () {
      expect(revisionPendiente([rev(fecha: haceDias(7))], ahora: ahora), isFalse);
      expect(revisionPendiente([rev(fecha: haceDias(8))], ahora: ahora), isTrue);
    });
  });

  group('alertas', () {
    final cel = equipo(TipoEquipo.celular);

    test('almacenamiento 90 no, 91 crítica', () {
      expect(calcularAlertas(cel, [rev(alm: 90)], ahora: ahora), isEmpty);
      final a = calcularAlertas(cel, [rev(alm: 91)], ahora: ahora);
      expect(a.single.nivel, NivelAlerta.critica);
      expect(a.single.mensaje, contains('91%'));
    });

    test('batería 80 no, 79 advertencia', () {
      expect(calcularAlertas(cel, [rev(bat: 80)], ahora: ahora), isEmpty);
      expect(calcularAlertas(cel, [rev(bat: 79)], ahora: ahora).single.nivel, NivelAlerta.advertencia);
    });

    test('sobrecalentamiento', () {
      expect(calcularAlertas(cel, [rev(sobre: false)], ahora: ahora), isEmpty);
      expect(calcularAlertas(cel, [rev(sobre: true)], ahora: ahora).single.nivel, NivelAlerta.advertencia);
    });

    test('solo cuenta la revisión más reciente', () {
      final revs = [rev(alm: 50), rev(alm: 99, fecha: haceDias(7))];
      expect(calcularAlertas(cel, revs, ahora: ahora), isEmpty);
    });

    test('mantenimiento: 365 no, 366 sí (desde la compra)', () {
      final l365 = equipo(TipoEquipo.laptop, compra: haceDias(365));
      final l366 = equipo(TipoEquipo.laptop, compra: haceDias(366));
      expect(calcularAlertas(l365, [], ahora: ahora), isEmpty);
      expect(calcularAlertas(l366, [], ahora: ahora).single.mensaje, 'Mantenimiento preventivo vencido');
    });

    test('mantenimiento usa la última revisión con mantenimiento', () {
      final pc = equipo(TipoEquipo.pc, compra: haceDias(800));
      final revs = [rev(), rev(fecha: haceDias(100), mant: true)];
      expect(calcularAlertas(pc, revs, ahora: ahora), isEmpty);
    });

    test('mantenimiento no aplica a celular', () {
      final c = equipo(TipoEquipo.celular, compra: haceDias(800));
      expect(calcularAlertas(c, [], ahora: ahora), isEmpty);
    });

    test('vida útil superada', () {
      final r = equipo(TipoEquipo.reloj, compra: haceDias(1300));
      expect(calcularAlertas(r, [], ahora: ahora).single.mensaje, 'Superó su vida útil estimada');
    });
  });

  group('nivelGeneral', () {
    test('vacío es ok', () => expect(nivelGeneral([]), NivelAlerta.ok));

    test('peor nivel', () {
      const adv = Alerta(NivelAlerta.advertencia, 'a');
      const cri = Alerta(NivelAlerta.critica, 'c');
      expect(nivelGeneral([adv]), NivelAlerta.advertencia);
      expect(nivelGeneral([adv, cri, adv]), NivelAlerta.critica);
    });
  });
}
