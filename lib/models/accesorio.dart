import 'tipo_equipo.dart';

class Accesorio {
  final int? id;
  final int equipoId;
  final TipoAccesorio tipo;
  final String? descripcion;
  final DateTime? fechaCompra;
  final EstadoAccesorio estado;

  const Accesorio({
    this.id,
    required this.equipoId,
    required this.tipo,
    this.descripcion,
    this.fechaCompra,
    required this.estado,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'equipo_id': equipoId,
        'tipo': tipo.name,
        'descripcion': descripcion,
        'fecha_compra': fechaCompra?.toIso8601String(),
        'estado': estado.name,
      };

  factory Accesorio.fromMap(Map<String, dynamic> map) => Accesorio(
        id: map['id'] as int?,
        equipoId: map['equipo_id'] as int,
        tipo: TipoAccesorio.values.byName(map['tipo'] as String),
        descripcion: map['descripcion'] as String?,
        fechaCompra: map['fecha_compra'] == null
            ? null
            : DateTime.parse(map['fecha_compra'] as String),
        estado: EstadoAccesorio.values.byName(map['estado'] as String),
      );
}
