// Revisión semanal. Los campos que no aplican al tipo de equipo quedan en null.
class Revision {
  final int? id;
  final int equipoId;
  final DateTime fecha;
  final bool limpieza;
  final int? almacenamientoPct;
  final int? bateriaPct;
  final bool? sobrecalentamiento;
  final bool? mantenimiento;
  final String? observaciones;
  final String? fotoPath;

  const Revision({
    this.id,
    required this.equipoId,
    required this.fecha,
    required this.limpieza,
    this.almacenamientoPct,
    this.bateriaPct,
    this.sobrecalentamiento,
    this.mantenimiento,
    this.observaciones,
    this.fotoPath,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'equipo_id': equipoId,
        'fecha': fecha.toIso8601String(),
        'limpieza': limpieza ? 1 : 0,
        'almacenamiento_pct': almacenamientoPct,
        'bateria_pct': bateriaPct,
        'sobrecalentamiento': _boolAInt(sobrecalentamiento),
        'mantenimiento': _boolAInt(mantenimiento),
        'observaciones': observaciones,
        'foto_path': fotoPath,
      };

  factory Revision.fromMap(Map<String, dynamic> map) => Revision(
        id: map['id'] as int?,
        equipoId: map['equipo_id'] as int,
        fecha: DateTime.parse(map['fecha'] as String),
        limpieza: map['limpieza'] == 1,
        almacenamientoPct: map['almacenamiento_pct'] as int?,
        bateriaPct: map['bateria_pct'] as int?,
        sobrecalentamiento: _intABool(map['sobrecalentamiento']),
        mantenimiento: _intABool(map['mantenimiento']),
        observaciones: map['observaciones'] as String?,
        fotoPath: map['foto_path'] as String?,
      );

  static int? _boolAInt(bool? v) => v == null ? null : (v ? 1 : 0);

  static bool? _intABool(Object? v) => v == null ? null : v == 1;
}
