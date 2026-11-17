import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/accesorio_repository.dart';
import '../../data/equipo_repository.dart';
import '../../data/revision_repository.dart';
import '../../logic/estado_equipo.dart';
import '../../models/accesorio.dart';
import '../../models/equipo.dart';
import '../../models/revision.dart';
import '../../models/tipo_equipo.dart';
import '../../routes.dart';
import '../../utils/fechas.dart';
import '../widgets/alerta_chip.dart';
import '../widgets/barra_indicador.dart';
import '../widgets/dialogo_accesorio.dart';
import '../widgets/foto_equipo.dart';

typedef _Datos = (Equipo?, List<Revision>, List<Accesorio>);

// arguments: Equipo. Se recarga de la BD, pero la foto se pinta desde el inicio para el Hero.
class PantallaDetalleEquipo extends StatefulWidget {
  const PantallaDetalleEquipo({super.key});

  @override
  State<PantallaDetalleEquipo> createState() => _PantallaDetalleEquipoState();
}

class _PantallaDetalleEquipoState extends State<PantallaDetalleEquipo> {
  late Equipo _inicial;
  late int _id;
  late Future<_Datos> _futuro;
  bool _inicializado = false;
  bool _cerrando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      _inicial = ModalRoute.of(context)!.settings.arguments as Equipo;
      _id = _inicial.id!;
      _futuro = _cargar();
      _inicializado = true;
    }
  }

  Future<_Datos> _cargar() async {
    final equipo = await EquipoRepository().obtenerPorId(_id);
    final revisiones = await RevisionRepository().obtenerPorEquipo(_id);
    final accesorios = await AccesorioRepository().obtenerPorEquipo(_id);
    return (equipo, revisiones, accesorios);
  }

  void _recargar() {
    setState(() {
      _futuro = _cargar();
    });
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<bool> _confirmar(String titulo, String texto) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    return r ?? false;
  }

  // Ejecuta una operación de BD mostrando errores en SnackBar.
  Future<bool> _intentar(Future<void> Function() accion, String fallo) async {
    try {
      await accion();
      return true;
    } on DatabaseException {
      if (mounted) _mensaje('$fallo (error de base de datos)');
    } catch (_) {
      if (mounted) _mensaje(fallo);
    }
    return false;
  }

  Future<void> _editar(Equipo e) async {
    final r = await Navigator.pushNamed(context, Rutas.formEquipo, arguments: e);
    if (r == true) _recargar();
  }

  Future<void> _nuevaRevision(Equipo e) async {
    final r = await Navigator.pushNamed(context, Rutas.formRevision, arguments: e);
    if (r == true) _recargar();
  }

  Future<void> _eliminarEquipo(Equipo e) async {
    if (!await _confirmar('Eliminar equipo',
        '¿Eliminar "${e.nombre}" con sus revisiones y accesorios?')) {
      return;
    }
    final ok = await _intentar(
        () => EquipoRepository().eliminar(e.id!), 'No se pudo eliminar el equipo');
    if (ok && mounted) Navigator.pop(context, true);
  }

  Future<void> _eliminarRevision(Revision r) async {
    if (!await _confirmar('Eliminar revisión',
        '¿Eliminar la revisión del ${formatearFecha(r.fecha)}?')) {
      return;
    }
    if (await _intentar(() => RevisionRepository().eliminar(r.id!),
        'No se pudo eliminar la revisión')) {
      _recargar();
    }
  }

  Future<void> _eliminarAccesorio(Accesorio a) async {
    if (!await _confirmar(
        'Eliminar accesorio', '¿Eliminar "${a.tipo.etiqueta}"?')) {
      return;
    }
    if (await _intentar(() => AccesorioRepository().eliminar(a.id!),
        'No se pudo eliminar el accesorio')) {
      _recargar();
    }
  }

  Future<void> _accesorio(Equipo e, [Accesorio? a]) async {
    final r = await mostrarDialogoAccesorio(context, equipo: e, accesorio: a);
    if (r == true) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Datos>(
      future: _futuro,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          case ConnectionState.active:
            return Scaffold(
              appBar: AppBar(title: Text(_inicial.nombre)),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(child: FotoEquipo(equipo: _inicial, tamano: 160)),
                  const SizedBox(height: 32),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
            );
          case ConnectionState.done:
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Detalle')),
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No se pudo cargar el equipo'),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _recargar, child: const Text('Reintentar')),
                    ],
                  ),
                ),
              );
            }
            final (equipo, revisiones, accesorios) = snapshot.data!;
            if (equipo == null) {
              // Ya no existe: regresar una sola vez para que la lista se actualice.
              if (!_cerrando) {
                _cerrando = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Navigator.pop(context, true);
                });
              }
              return const Scaffold(body: SizedBox.shrink());
            }
            return _contenido(equipo, revisiones, accesorios);
        }
      },
    );
  }

  Widget _contenido(Equipo e, List<Revision> revisiones, List<Accesorio> accesorios) {
    final tema = Theme.of(context);
    final alertas = calcularAlertas(e, revisiones);
    return Scaffold(
      appBar: AppBar(
        title: Text(e.nombre),
        actions: [
          IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: () => _editar(e)),
          IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete),
              onPressed: () => _eliminarEquipo(e)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _nuevaRevision(e),
        icon: const Icon(Icons.fact_check),
        label: const Text('Nueva revisión'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Center(child: FotoEquipo(equipo: e, tamano: 160)),
          const SizedBox(height: 16),
          Text('Ficha técnica', style: tema.textTheme.titleMedium),
          ..._ficha(e),
          const Divider(height: 32),
          ..._indicadores(e, revisiones),
          const Divider(height: 32),
          Text('Alertas', style: tema.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (alertas.isEmpty)
            const Text('Sin alertas')
          else
            Wrap(spacing: 8, children: [for (final a in alertas) AlertaChip(alerta: a)]),
          if (revisionPendiente(revisiones))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Revisión pendiente: han pasado más de 7 días.'),
            ),
          const Divider(height: 32),
          Text('Historial de revisiones', style: tema.textTheme.titleMedium),
          if (revisiones.isEmpty) const Text('Aún no hay revisiones'),
          for (final r in revisiones) _tarjetaRevision(r),
          const Divider(height: 32),
          Text('Accesorios', style: tema.textTheme.titleMedium),
          if (accesorios.isEmpty) const Text('Sin accesorios'),
          for (final a in accesorios) _tileAccesorio(e, a),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _accesorio(e),
              icon: const Icon(Icons.add),
              label: const Text('Agregar accesorio'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _ficha(Equipo e) {
    final c = e.tipo.camposFicha;
    final filas = <(String, String?)>[
      ('Tipo', e.tipo.etiqueta),
      ('Marca', e.marca),
      ('Modelo', e.modelo),
      ('Fecha de compra', formatearFecha(e.fechaCompra)),
      if (c.contains(CampoFicha.numeroSerie)) ('Número de serie', e.numeroSerie),
      if (c.contains(CampoFicha.procesador)) ('Procesador', e.procesador),
      if (c.contains(CampoFicha.ramGb)) ('RAM', e.ramGb == null ? null : '${e.ramGb} GB'),
      if (c.contains(CampoFicha.almacenamientoGb))
        ('Almacenamiento',
            e.almacenamientoGb == null ? null : '${e.almacenamientoGb} GB'),
      ('Notas', e.notas),
    ];
    return [
      for (final (k, v) in filas)
        if (v != null && v.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: 130,
                    child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
                Expanded(child: Text(v)),
              ],
            ),
          ),
    ];
  }

  List<Widget> _indicadores(Equipo e, List<Revision> revisiones) {
    final pct = porcentajeVidaUtil(e.fechaCompra, e.tipo.vidaUtilMeses);
    final c = e.tipo.camposRevision;
    final usaRevision =
        c.contains(CampoRevision.almacenamientoUsado) || c.contains(CampoRevision.bateriaPct);
    return [
      Text('Indicadores', style: Theme.of(context).textTheme.titleMedium),
      Text('Etapa: ${etapaVida(pct).etiqueta}'),
      for (final i in indicadores(e, revisiones)) BarraIndicador(indicador: i),
      if (revisiones.isEmpty && usaRevision)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Registra una revisión para ver almacenamiento y batería.'),
        ),
    ];
  }

  String _resumen(Revision r) {
    final partes = <String>[
      r.limpieza ? 'Limpieza hecha' : 'Sin limpieza',
      if (r.almacenamientoUsadoGb != null) 'Almac. ${r.almacenamientoUsadoGb} GB',
      if (r.bateriaPct != null) 'Batería ${r.bateriaPct}%',
      if (r.sobrecalentamiento == true) 'Se calienta',
      if (r.mantenimiento == true) 'Mantenimiento',
      if (r.observaciones != null && r.observaciones!.isNotEmpty) r.observaciones!,
    ];
    return partes.join(' · ');
  }

  Widget _tarjetaRevision(Revision r) {
    final foto = r.fotoPath;
    return Card(
      child: ListTile(
        leading: foto != null && File(foto).existsSync()
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(File(foto), width: 48, height: 48, fit: BoxFit.cover),
              )
            : const Icon(Icons.fact_check_outlined),
        title: Text(formatearFecha(r.fecha)),
        subtitle: Text(_resumen(r)),
        trailing: IconButton(
          tooltip: 'Eliminar revisión',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _eliminarRevision(r),
        ),
      ),
    );
  }

  Widget _tileAccesorio(Equipo e, Accesorio a) {
    final f = a.fechaCompra;
    final vida = f == null ? null : porcentajeVidaUtil(f, a.tipo.vidaUtilMeses);
    final desc = a.descripcion;
    return Card(
      child: ListTile(
        onTap: () => _accesorio(e, a),
        title: Text(a.tipo.etiqueta),
        subtitle: Text([
          if (desc != null && desc.isNotEmpty) desc,
          'Estado: ${a.estado.etiqueta}',
          if (f != null) 'Compra: ${formatearFecha(f)}',
          if (vida != null) 'Vida útil: ${etapaVida(vida).etiqueta}',
        ].join('\n')),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: 'Eliminar accesorio',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _eliminarAccesorio(a),
        ),
      ),
    );
  }
}
