import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/revision_repository.dart';
import '../../models/equipo.dart';
import '../../models/revision.dart';
import '../../models/tipo_equipo.dart';
import '../../services/media_service.dart';
import '../widgets/campo_dictado.dart';
import '../widgets/foto_picker.dart';

// arguments: Equipo. pop(true) si guardó.
class PantallaFormRevision extends StatefulWidget {
  const PantallaFormRevision({super.key});

  @override
  State<PantallaFormRevision> createState() => _PantallaFormRevisionState();
}

class _PantallaFormRevisionState extends State<PantallaFormRevision> {
  final _formKey = GlobalKey<FormState>();
  final _almacenamiento = TextEditingController();
  final _bateria = TextEditingController();
  final _observaciones = TextEditingController();
  late Equipo _equipo;
  bool _inicializado = false;
  bool _limpieza = false;
  bool _calienta = false;
  bool _mantenimiento = false;
  bool _guardando = false;
  bool _guardado = false;
  String? _foto;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      _equipo = ModalRoute.of(context)!.settings.arguments as Equipo;
      _inicializado = true;
    }
  }

  @override
  void dispose() {
    _almacenamiento.dispose();
    _bateria.dispose();
    _observaciones.dispose();
    // Foto tomada pero no guardada: no dejar huérfanos.
    if (!_guardado) MediaService().eliminarFoto(_foto);
    super.dispose();
  }

  Future<void> _cambiarFoto(String? nueva) async {
    final anterior = _foto;
    setState(() => _foto = nueva);
    // La foto anterior de este formulario ya no se usará.
    await MediaService().eliminarFoto(anterior);
  }

  String? _validarPct(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null || n < 0 || n > 100) return 'Ingresa un valor entre 0 y 100';
    return null;
  }

  // GB usados: entre 0 y el total registrado en la ficha.
  String? _validarGb(String? v) {
    final total = _equipo.almacenamientoGb;
    if (total == null) return 'Registra el almacenamiento total en la ficha del equipo';
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null || n < 0 || n > total) return 'Ingresa un valor entre 0 y $total GB';
    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final campos = _equipo.tipo.camposRevision;
    final obs = _observaciones.text.trim();
    final revision = Revision(
      equipoId: _equipo.id!,
      fecha: DateTime.now(),
      limpieza: _limpieza,
      almacenamientoUsadoGb: campos.contains(CampoRevision.almacenamientoUsado)
          ? int.parse(_almacenamiento.text.trim())
          : null,
      bateriaPct: campos.contains(CampoRevision.bateriaPct)
          ? int.parse(_bateria.text.trim())
          : null,
      sobrecalentamiento:
          campos.contains(CampoRevision.sobrecalentamiento) ? _calienta : null,
      mantenimiento:
          campos.contains(CampoRevision.mantenimiento) ? _mantenimiento : null,
      observaciones: obs.isEmpty ? null : obs,
      fotoPath: _foto,
    );
    setState(() => _guardando = true);
    try {
      await RevisionRepository().insertar(revision);
      _guardado = true;
      if (mounted) Navigator.pop(context, true);
    } on DatabaseException {
      _error('No se pudo guardar la revisión en la base de datos');
    } catch (_) {
      _error('Ocurrió un error al guardar la revisión');
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final campos = _equipo.tipo.camposRevision;
    return Scaffold(
      appBar: AppBar(title: Text('Revisión de ${_equipo.nombre}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Limpieza superficial'),
              value: _limpieza,
              onChanged: (v) => setState(() => _limpieza = v),
            ),
            if (campos.contains(CampoRevision.almacenamientoUsado))
              TextFormField(
                controller: _almacenamiento,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Almacenamiento usado (GB)',
                  helperText:
                      'Total: ${_equipo.almacenamientoGb ?? '?'} GB · máx. recomendado 90%',
                ),
                validator: _validarGb,
              ),
            if (campos.contains(CampoRevision.bateriaPct))
              TextFormField(
                controller: _bateria,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Salud de batería (%)',
                  helperText: 'Menos de 80% indica desgaste',
                ),
                validator: _validarPct,
              ),
            if (campos.contains(CampoRevision.sobrecalentamiento))
              SwitchListTile(
                title: const Text('Se calienta en exceso'),
                value: _calienta,
                onChanged: (v) => setState(() => _calienta = v),
              ),
            if (campos.contains(CampoRevision.mantenimiento))
              SwitchListTile(
                title: const Text('Se hizo mantenimiento preventivo'),
                subtitle: const Text('Recomendado al menos una vez al año'),
                value: _mantenimiento,
                onChanged: (v) => setState(() => _mantenimiento = v),
              ),
            const SizedBox(height: 12),
            CampoDictado(controller: _observaciones, etiqueta: 'Observaciones'),
            const SizedBox(height: 12),
            FotoPicker(fotoPath: _foto, onCambio: _cambiarFoto),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.save),
              label: const Text('Guardar revisión'),
            ),
          ],
        ),
      ),
    );
  }
}
