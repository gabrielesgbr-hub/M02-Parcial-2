import 'package:flutter_test/flutter_test.dart';
import 'package:m02_parcial2/logic/estado_equipo.dart';
import 'package:m02_parcial2/models/equipo.dart';
import 'package:m02_parcial2/models/revision.dart';
import 'package:m02_parcial2/models/tipo_equipo.dart';

final ahora = DateTime(2025, 6, 1);

// Total de 100 GB: los GB usados equivalen al porcentaje.
Equipo equipo(TipoEquipo tipo, {DateTime? compra, int? totalGb = 100}) => Equipo(
      tipo: tipo,
      nombre: 'x',
      almacenamientoGb: totalGb,
      fechaCompra: compra ?? DateTime(2025, 5, 1),
      creadoEn: ahora,
    );

Revision rev({DateTime? fecha, int? alm, int? bat, bool? sobre, bool? mant}) => Revision(
      equipoId: 1,
      fecha: fecha ?? ahora,
      limpieza: true,
      almacenamientoUsadoGb: alm,
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

    test('almacenamiento: 84 no, 85-90 advertencia, 91 crítica', () {
      expect(calcularAlertas(cel, [rev(alm: 84)], ahora: ahora), isEmpty);
      expect(calcularAlertas(cel, [rev(alm: 90)], ahora: ahora).single.nivel, NivelAlerta.advertencia);
      final a = calcularAlertas(cel, [rev(alm: 91)], ahora: ahora);
      expect(a.single.nivel, NivelAlerta.critica);
      expect(a.single.mensaje, contains('91%'));
    });

    test('almacenamiento se calcula contra el total', () {
      final c = equipo(TipoEquipo.celular, totalGb: 256);
      expect(porcentajeAlmacenamiento(c, rev(alm: 230)), 90);
      expect(porcentajeAlmacenamiento(equipo(TipoEquipo.celular, totalGb: null), rev(alm: 10)), isNull);
    });

    test('batería: 80 no, 60-79 advertencia, 59 crítica', () {
      expect(calcularAlertas(cel, [rev(bat: 80)], ahora: ahora), isEmpty);
      expect(calcularAlertas(cel, [rev(bat: 60)], ahora: ahora).single.nivel, NivelAlerta.advertencia);
      expect(calcularAlertas(cel, [rev(bat: 59)], ahora: ahora).single.nivel, NivelAlerta.critica);
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

    test('vida útil: cerca del fin (advertencia) y superada (crítica)', () {
      // Reloj: 42 meses ≈ 1278 días.
      final cerca = calcularAlertas(equipo(TipoEquipo.reloj, compra: haceDias(1100)), [], ahora: ahora);
      expect(cerca.single.nivel, NivelAlerta.advertencia);
      final fin = calcularAlertas(equipo(TipoEquipo.reloj, compra: haceDias(1300)), [], ahora: ahora);
      expect(fin.single.nivel, NivelAlerta.critica);
      expect(fin.single.mensaje, 'Superó su vida útil estimada');
    });
  });

  group('indicadores', () {
    test('cortes de vida útil', () {
      expect(nivelVidaUtil(0.84), NivelAlerta.ok);
      expect(nivelVidaUtil(0.85), NivelAlerta.advertencia);
      expect(nivelVidaUtil(1.0), NivelAlerta.critica);
    });

    test('vida útil en meses y barra llena al pasarse', () {
      final r = equipo(TipoEquipo.reloj, compra: haceDias(1300));
      final i = indicadores(r, [], ahora: ahora).single;
      expect(i.texto, '42 de 42 meses');
      expect(i.valor, 1.0);
    });

    test('sin revisiones solo vida útil; con revisión agrega almacenamiento y batería', () {
      final t = equipo(TipoEquipo.tablet);
      expect(indicadores(t, [], ahora: ahora).length, 1);
      final lista = indicadores(t, [rev(alm: 50, bat: 70)], ahora: ahora);
      expect(lista.map((i) => i.etiqueta), ['Vida útil', 'Almacenamiento', 'Batería']);
      expect(indicadorMasPreocupante(lista).etiqueta, 'Batería');
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
