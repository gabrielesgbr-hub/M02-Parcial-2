import 'package:flutter_test/flutter_test.dart';
import 'package:m02_parcial2/models/accesorio.dart';
import 'package:m02_parcial2/models/equipo.dart';
import 'package:m02_parcial2/models/revision.dart';
import 'package:m02_parcial2/models/tipo_equipo.dart';

void main() {
  test('Equipo: toMap -> fromMap conserva los datos', () {
    final e = Equipo(
      id: 3,
      tipo: TipoEquipo.laptop,
      nombre: 'Mi laptop',
      marca: 'Lenovo',
      numeroSerie: 'SN123',
      ramGb: 16,
      almacenamientoGb: 512,
      fechaCompra: DateTime(2024, 2, 10),
      creadoEn: DateTime(2024, 2, 11, 9, 30),
    );
    final c = Equipo.fromMap(e.toMap());
    expect(c.id, 3);
    expect(c.tipo, TipoEquipo.laptop);
    expect(c.nombre, 'Mi laptop');
    expect(c.marca, 'Lenovo');
    expect(c.modelo, isNull);
    expect(c.numeroSerie, 'SN123');
    expect(c.procesador, isNull);
    expect(c.ramGb, 16);
    expect(c.almacenamientoGb, 512);
    expect(c.fechaCompra, DateTime(2024, 2, 10));
    expect(c.fotoPath, isNull);
    expect(c.creadoEn, DateTime(2024, 2, 11, 9, 30));
  });

  test('toMap no incluye id cuando es null', () {
    final e = Equipo(
      tipo: TipoEquipo.audifonos,
      nombre: 'x',
      fechaCompra: DateTime(2024),
      creadoEn: DateTime(2024),
    );
    expect(e.toMap().containsKey('id'), isFalse);
  });

  test('Revision: conserva bools null/true/false', () {
    final r = Revision(
      id: 1,
      equipoId: 3,
      fecha: DateTime(2025, 1, 5),
      limpieza: false,
      almacenamientoPct: 85,
      sobrecalentamiento: true,
      mantenimiento: false,
      observaciones: 'Ventilador ruidoso',
    );
    final c = Revision.fromMap(r.toMap());
    expect(c.equipoId, 3);
    expect(c.fecha, DateTime(2025, 1, 5));
    expect(c.limpieza, isFalse);
    expect(c.almacenamientoPct, 85);
    expect(c.bateriaPct, isNull);
    expect(c.sobrecalentamiento, isTrue);
    expect(c.mantenimiento, isFalse);
    expect(c.observaciones, 'Ventilador ruidoso');
  });

  test('Accesorio: conserva enums y fecha opcional', () {
    const a = Accesorio(
      equipoId: 3,
      tipo: TipoAccesorio.cargador,
      estado: EstadoAccesorio.regular,
    );
    final c = Accesorio.fromMap(a.toMap());
    expect(c.tipo, TipoAccesorio.cargador);
    expect(c.estado, EstadoAccesorio.regular);
    expect(c.fechaCompra, isNull);
    expect(c.descripcion, isNull);

    final conFecha = Accesorio.fromMap(
      Accesorio(
        equipoId: 3,
        tipo: TipoAccesorio.mouse,
        estado: EstadoAccesorio.bueno,
        fechaCompra: DateTime(2023, 7, 1),
      ).toMap(),
    );
    expect(conFecha.fechaCompra, DateTime(2023, 7, 1));
  });
}
