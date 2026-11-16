import 'tipo_equipo.dart';

// Los campos que no aplican al tipo quedan en null.
class Equipo {
  final int? id;
  final TipoEquipo tipo;
  final String nombre;
  final String? marca;
  final String? modelo;
  final String? numeroSerie;
  final String? procesador;
  final int? ramGb;
  final int? almacenamientoGb;
  final DateTime fechaCompra;
  final String? fotoPath;
  final String? notas;
  final DateTime creadoEn;

  const Equipo({
    this.id,
    required this.tipo,
    required this.nombre,
    this.marca,
    this.modelo,
    this.numeroSerie,
    this.procesador,
    this.ramGb,
    this.almacenamientoGb,
    required this.fechaCompra,
    this.fotoPath,
    this.notas,
    required this.creadoEn,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'tipo': tipo.name,
        'nombre': nombre,
        'marca': marca,
        'modelo': modelo,
        'numero_serie': numeroSerie,
        'procesador': procesador,
        'ram_gb': ramGb,
        'almacenamiento_gb': almacenamientoGb,
        'fecha_compra': fechaCompra.toIso8601String(),
        'foto_path': fotoPath,
        'notas': notas,
        'creado_en': creadoEn.toIso8601String(),
      };

  factory Equipo.fromMap(Map<String, dynamic> map) => Equipo(
        id: map['id'] as int?,
        tipo: TipoEquipo.values.byName(map['tipo'] as String),
        nombre: map['nombre'] as String,
        marca: map['marca'] as String?,
        modelo: map['modelo'] as String?,
        numeroSerie: map['numero_serie'] as String?,
        procesador: map['procesador'] as String?,
        ramGb: map['ram_gb'] as int?,
        almacenamientoGb: map['almacenamiento_gb'] as int?,
        fechaCompra: DateTime.parse(map['fecha_compra'] as String),
        fotoPath: map['foto_path'] as String?,
        notas: map['notas'] as String?,
        creadoEn: DateTime.parse(map['creado_en'] as String),
      );
}
