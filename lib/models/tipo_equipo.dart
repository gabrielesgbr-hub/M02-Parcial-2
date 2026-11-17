import 'package:material_ui/material_ui.dart';

// Campos de la ficha que dependen del tipo (nombre, marca, modelo, fecha, foto y notas aplican a todos).
enum CampoFicha { numeroSerie, procesador, ramGb, almacenamientoGb }

// Campos de la revisión que dependen del tipo (limpieza, observaciones y foto aplican a todos).
enum CampoRevision { almacenamientoUsado, bateriaPct, sobrecalentamiento, mantenimiento }

// Tipos fijos de accesorio con su vida útil en meses.
enum TipoAccesorio {
  cargador('Cargador (cubo)', 42),
  cableUsb('Cable USB', 18),
  mouse('Mouse', 48),
  teclado('Teclado', 48),
  monitor('Monitor', 72),
  funda('Funda / mochila', 24),
  protectorPantalla('Protector de pantalla', 12),
  lapiz('Lápiz', 36),
  baseCarga('Cargador / base', 42),
  correa('Correa', 18),
  estucheCarga('Estuche de carga', 30),
  almohadillas('Almohadillas', 18);

  const TipoAccesorio(this.etiqueta, this.vidaUtilMeses);

  final String etiqueta;
  final int vidaUtilMeses;
}

enum EstadoAccesorio {
  bueno('Bueno'),
  regular('Regular'),
  malo('Malo');

  const EstadoAccesorio(this.etiqueta);

  final String etiqueta;
}

// Tipos fijos de equipo: el usuario no puede crearlos, editarlos ni borrarlos.
enum TipoEquipo {
  laptop(
    etiqueta: 'Laptop',
    icono: Icons.laptop,
    vidaUtilMeses: 54,
    camposFicha: {
      CampoFicha.numeroSerie,
      CampoFicha.procesador,
      CampoFicha.ramGb,
      CampoFicha.almacenamientoGb,
    },
    camposRevision: {
      CampoRevision.almacenamientoUsado,
      CampoRevision.bateriaPct,
      CampoRevision.sobrecalentamiento,
      CampoRevision.mantenimiento,
    },
    accesorios: [
      TipoAccesorio.cargador,
      TipoAccesorio.mouse,
      TipoAccesorio.teclado,
      TipoAccesorio.cableUsb,
      TipoAccesorio.funda,
      TipoAccesorio.monitor,
      TipoAccesorio.protectorPantalla,
    ],
  ),
  pc(
    etiqueta: 'PC de escritorio',
    icono: Icons.desktop_windows,
    vidaUtilMeses: 72,
    camposFicha: {
      CampoFicha.numeroSerie,
      CampoFicha.procesador,
      CampoFicha.ramGb,
      CampoFicha.almacenamientoGb,
    },
    camposRevision: {
      CampoRevision.almacenamientoUsado,
      CampoRevision.sobrecalentamiento,
      CampoRevision.mantenimiento,
    },
    accesorios: [
      TipoAccesorio.mouse,
      TipoAccesorio.teclado,
      TipoAccesorio.monitor,
      TipoAccesorio.cableUsb,
      TipoAccesorio.funda,
    ],
  ),
  celular(
    etiqueta: 'Celular',
    icono: Icons.smartphone,
    vidaUtilMeses: 42,
    camposFicha: {CampoFicha.numeroSerie, CampoFicha.almacenamientoGb},
    camposRevision: {
      CampoRevision.almacenamientoUsado,
      CampoRevision.bateriaPct,
      CampoRevision.sobrecalentamiento,
    },
    accesorios: [
      TipoAccesorio.cargador,
      TipoAccesorio.cableUsb,
      TipoAccesorio.funda,
      TipoAccesorio.protectorPantalla,
      TipoAccesorio.baseCarga,
      TipoAccesorio.estucheCarga,
    ],
  ),
  tablet(
    etiqueta: 'Tablet',
    icono: Icons.tablet_mac,
    vidaUtilMeses: 54,
    camposFicha: {CampoFicha.numeroSerie, CampoFicha.almacenamientoGb},
    camposRevision: {
      CampoRevision.almacenamientoUsado,
      CampoRevision.bateriaPct,
      CampoRevision.sobrecalentamiento,
    },
    accesorios: [
      TipoAccesorio.cargador,
      TipoAccesorio.cableUsb,
      TipoAccesorio.funda,
      TipoAccesorio.protectorPantalla,
      TipoAccesorio.lapiz,
      TipoAccesorio.teclado,
      TipoAccesorio.mouse,
      TipoAccesorio.baseCarga,
    ],
  ),
  reloj(
    etiqueta: 'Reloj inteligente',
    icono: Icons.watch,
    vidaUtilMeses: 42,
    camposFicha: {CampoFicha.numeroSerie},
    camposRevision: {CampoRevision.bateriaPct},
    accesorios: [
      TipoAccesorio.baseCarga,
      TipoAccesorio.correa,
      TipoAccesorio.cableUsb,
      TipoAccesorio.protectorPantalla,
    ],
  ),
  audifonos(
    etiqueta: 'Audífonos',
    icono: Icons.headphones,
    vidaUtilMeses: 30,
    camposFicha: {CampoFicha.numeroSerie},
    camposRevision: {CampoRevision.bateriaPct},
    accesorios: [
      TipoAccesorio.estucheCarga,
      TipoAccesorio.cableUsb,
      TipoAccesorio.almohadillas,
      TipoAccesorio.cargador,
      TipoAccesorio.funda,
    ],
  );

  const TipoEquipo({
    required this.etiqueta,
    required this.icono,
    required this.vidaUtilMeses,
    required this.camposFicha,
    required this.camposRevision,
    required this.accesorios,
  });

  final String etiqueta;
  final IconData icono;
  final int vidaUtilMeses;
  final Set<CampoFicha> camposFicha;
  final Set<CampoRevision> camposRevision;
  final List<TipoAccesorio> accesorios;
}
