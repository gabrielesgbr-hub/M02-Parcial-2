import '../models/equipo.dart';
import '../models/revision.dart';
import '../models/tipo_equipo.dart';

// Reglas de salud del equipo. Funciones puras; `ahora` se inyecta para poder probarlas.

enum NivelAlerta { ok, advertencia, critica }

class Alerta {
  final NivelAlerta nivel;
  final String mensaje;

  const Alerta(this.nivel, this.mensaje);
}

enum EtapaVida {
  nuevo('Nuevo'),
  buenEstado('En buen estado'),
  envejeciendo('Envejeciendo'),
  finVida('Fin de vida útil');

  const EtapaVida(this.etiqueta);

  final String etiqueta;
}

// Edad / vida útil (0.0 = nuevo, 1.0 = vida útil cumplida; puede pasar de 1).
double porcentajeVidaUtil(
  DateTime fechaCompra,
  int vidaUtilMeses, {
  DateTime? ahora,
}) {
  final dias = (ahora ?? DateTime.now()).difference(fechaCompra).inDays;
  if (dias <= 0) return 0;
  return dias / (vidaUtilMeses * 30.44);
}

// <0.5 nuevo, <0.8 buen estado, <1.0 envejeciendo, >=1.0 fin de vida.
EtapaVida etapaVida(double porcentaje) {
  if (porcentaje < 0.5) return EtapaVida.nuevo;
  if (porcentaje < 0.8) return EtapaVida.buenEstado;
  if (porcentaje < 1.0) return EtapaVida.envejeciendo;
  return EtapaVida.finVida;
}

// Meses completos desde la compra.
int mesesDesde(DateTime fecha, {DateTime? ahora}) {
  final dias = (ahora ?? DateTime.now()).difference(fecha).inDays;
  return dias <= 0 ? 0 : (dias / 30.44).floor();
}

// % usado (redondeado) contra el total del equipo; null si falta algún dato.
int? porcentajeAlmacenamiento(Equipo equipo, Revision revision) {
  final total = equipo.almacenamientoGb, usado = revision.almacenamientoUsadoGb;
  if (total == null || total <= 0 || usado == null) return null;
  return (usado * 100 / total).round();
}

// Cortes de color de los indicadores.
NivelAlerta nivelVidaUtil(double p) => p >= 1.0
    ? NivelAlerta.critica
    : (p >= 0.85 ? NivelAlerta.advertencia : NivelAlerta.ok);

NivelAlerta nivelAlmacenamiento(int pct) => pct > 90
    ? NivelAlerta.critica
    : (pct >= 85 ? NivelAlerta.advertencia : NivelAlerta.ok);

NivelAlerta nivelBateria(int pct) => pct < 60
    ? NivelAlerta.critica
    : (pct < 80 ? NivelAlerta.advertencia : NivelAlerta.ok);

// Una barra: valor 0..1, texto a mostrar y su color.
class Indicador {
  final String etiqueta;
  final double valor;
  final String texto;
  final NivelAlerta nivel;

  const Indicador(this.etiqueta, this.valor, this.texto, this.nivel);
}

// Vida útil siempre; almacenamiento y batería según la última revisión.
List<Indicador> indicadores(
  Equipo equipo,
  List<Revision> revisiones, {
  DateTime? ahora,
}) {
  final vida = porcentajeVidaUtil(
    equipo.fechaCompra,
    equipo.tipo.vidaUtilMeses,
    ahora: ahora,
  );
  final lista = [
    Indicador(
      'Vida útil',
      vida.clamp(0.0, 1.0),
      '${mesesDesde(equipo.fechaCompra, ahora: ahora)} de ${equipo.tipo.vidaUtilMeses} meses',
      nivelVidaUtil(vida),
    ),
  ];
  if (revisiones.isEmpty) return lista;
  final ultima = revisiones.first;
  final alm = porcentajeAlmacenamiento(equipo, ultima);
  if (alm != null) {
    lista.add(
      Indicador(
        'Almacenamiento',
        (alm / 100).clamp(0.0, 1.0),
        '${ultima.almacenamientoUsadoGb} de ${equipo.almacenamientoGb} GB ($alm%)',
        nivelAlmacenamiento(alm),
      ),
    );
  }
  final bat = ultima.bateriaPct;
  if (bat != null) {
    lista.add(
      Indicador(
        'Batería',
        (bat / 100).clamp(0.0, 1.0),
        '$bat%',
        nivelBateria(bat),
      ),
    );
  }
  return lista;
}

// El de peor nivel; en empate, el primero de la lista.
Indicador indicadorMasPreocupante(List<Indicador> lista) =>
    lista.reduce((a, b) => b.nivel.index > a.nivel.index ? b : a);

// Sin revisiones o la última tiene más de 7 días.
bool revisionPendiente(List<Revision> revisiones, {DateTime? ahora}) {
  if (revisiones.isEmpty) return true;
  return (ahora ?? DateTime.now()).difference(revisiones.first.fecha).inDays >
      7;
}

// Días que faltan para la próxima revisión semanal; null si ya está pendiente.
int? diasParaRevision(List<Revision> revisiones, {DateTime? ahora}) {
  if (revisionPendiente(revisiones, ahora: ahora)) return null;
  return 7 -
      (ahora ?? DateTime.now()).difference(revisiones.first.fecha).inDays;
}

// `revisiones` viene de la más reciente a la más antigua.
List<Alerta> calcularAlertas(
  Equipo equipo,
  List<Revision> revisiones, {
  DateTime? ahora,
}) {
  final hoy = ahora ?? DateTime.now();
  final alertas = <Alerta>[];

  if (revisiones.isNotEmpty) {
    final ultima = revisiones.first;
    final alm = porcentajeAlmacenamiento(equipo, ultima);
    final bat = ultima.bateriaPct;
    if (alm != null && nivelAlmacenamiento(alm) != NivelAlerta.ok) {
      alertas.add(
        Alerta(nivelAlmacenamiento(alm), 'Almacenamiento al $alm% (máx. 90%)'),
      );
    }
    if (bat != null && nivelBateria(bat) != NivelAlerta.ok) {
      alertas.add(Alerta(nivelBateria(bat), 'Salud de batería al $bat%'));
    }
    if (ultima.sobrecalentamiento == true) {
      alertas.add(
        const Alerta(NivelAlerta.advertencia, 'Se calienta en exceso'),
      );
    }
  }

  // Sin mantenimiento registrado se cuenta desde la compra.
  if (equipo.tipo.camposRevision.contains(CampoRevision.mantenimiento)) {
    final conMant = revisiones.where((r) => r.mantenimiento == true);
    final desde = conMant.isEmpty ? equipo.fechaCompra : conMant.first.fecha;
    if (hoy.difference(desde).inDays > 365) {
      alertas.add(
        const Alerta(
          NivelAlerta.advertencia,
          'Mantenimiento preventivo vencido',
        ),
      );
    }
  }

  final vida = nivelVidaUtil(
    porcentajeVidaUtil(
      equipo.fechaCompra,
      equipo.tipo.vidaUtilMeses,
      ahora: hoy,
    ),
  );
  if (vida == NivelAlerta.critica) {
    alertas.add(
      const Alerta(NivelAlerta.critica, 'Superó su vida útil estimada'),
    );
  } else if (vida == NivelAlerta.advertencia) {
    alertas.add(
      const Alerta(NivelAlerta.advertencia, 'Cerca del fin de su vida útil'),
    );
  }
  return alertas;
}

// La peor alerta; ok si no hay ninguna.
NivelAlerta nivelGeneral(List<Alerta> alertas) {
  var peor = NivelAlerta.ok;
  for (final a in alertas) {
    if (a.nivel.index > peor.index) peor = a.nivel;
  }
  return peor;
}
