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
double porcentajeVidaUtil(DateTime fechaCompra, int vidaUtilMeses, {DateTime? ahora}) {
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

// Sin revisiones o la última tiene más de 7 días.
bool revisionPendiente(List<Revision> revisiones, {DateTime? ahora}) {
  if (revisiones.isEmpty) return true;
  return (ahora ?? DateTime.now()).difference(revisiones.first.fecha).inDays > 7;
}

// `revisiones` viene de la más reciente a la más antigua.
List<Alerta> calcularAlertas(Equipo equipo, List<Revision> revisiones, {DateTime? ahora}) {
  final hoy = ahora ?? DateTime.now();
  final alertas = <Alerta>[];

  if (revisiones.isNotEmpty) {
    final ultima = revisiones.first;
    final alm = ultima.almacenamientoPct;
    final bat = ultima.bateriaPct;
    if (alm != null && alm > 90) {
      alertas.add(Alerta(NivelAlerta.critica, 'Almacenamiento al $alm% (máx. 90%)'));
    }
    if (bat != null && bat < 80) {
      alertas.add(Alerta(NivelAlerta.advertencia, 'Salud de batería al $bat%'));
    }
    if (ultima.sobrecalentamiento == true) {
      alertas.add(const Alerta(NivelAlerta.advertencia, 'Se calienta en exceso'));
    }
  }

  // Sin mantenimiento registrado se cuenta desde la compra.
  if (equipo.tipo.camposRevision.contains(CampoRevision.mantenimiento)) {
    final conMant = revisiones.where((r) => r.mantenimiento == true);
    final desde = conMant.isEmpty ? equipo.fechaCompra : conMant.first.fecha;
    if (hoy.difference(desde).inDays > 365) {
      alertas.add(const Alerta(NivelAlerta.advertencia, 'Mantenimiento preventivo vencido'));
    }
  }

  if (porcentajeVidaUtil(equipo.fechaCompra, equipo.tipo.vidaUtilMeses, ahora: hoy) >= 1.0) {
    alertas.add(const Alerta(NivelAlerta.advertencia, 'Superó su vida útil estimada'));
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
