import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/equipo_repository.dart';
import '../../models/equipo.dart';
import '../../models/tipo_equipo.dart';
import '../../services/media_service.dart';
import '../../utils/fechas.dart';
import '../widgets/campo_dictado.dart';
import '../widgets/foto_picker.dart';

// arguments: Equipo? (null = crear). pop(true) si guardó.
class PantallaFormEquipo extends StatefulWidget {
  const PantallaFormEquipo({super.key});

  @override
  State<PantallaFormEquipo> createState() => _PantallaFormEquipoState();
}

class _PantallaFormEquipoState extends State<PantallaFormEquipo> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _serie = TextEditingController();
  final _procesador = TextEditingController();
  final _ram = TextEditingController();
  final _almacenamiento = TextEditingController();
  final _notas = TextEditingController();
  Equipo? _original;
  bool _inicializado = false;
  TipoEquipo _tipo = TipoEquipo.laptop;
  DateTime? _fecha;
  String? _foto;
  bool _fechaInvalida = false;
  bool _guardando = false;
  bool _guardado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    final e = ModalRoute.of(context)!.settings.arguments as Equipo?;
    _original = e;
    if (e == null) return;
    _tipo = e.tipo;
    _nombre.text = e.nombre;
    _marca.text = e.marca ?? '';
    _modelo.text = e.modelo ?? '';
    _serie.text = e.numeroSerie ?? '';
    _procesador.text = e.procesador ?? '';
    _ram.text = e.ramGb?.toString() ?? '';
    _almacenamiento.text = e.almacenamientoGb?.toString() ?? '';
    _notas.text = e.notas ?? '';
    _fecha = e.fechaCompra;
    _foto = e.fotoPath;
  }

  @override
  void dispose() {
    for (final c in [
      _nombre, _marca, _modelo, _serie, _procesador, _ram, _almacenamiento, _notas
    ]) {
      c.dispose();
    }
    // Sin guardar: borrar solo la foto nueva, nunca la original.
    if (!_guardado && _foto != _original?.fotoPath) {
      MediaService().eliminarFoto(_foto);
    }
    super.dispose();
  }

  Future<void> _cambiarFoto(String? nueva) async {
    final anterior = _foto;
    setState(() => _foto = nueva);
    // Si la anterior era una nueva (no la original), se descarta.
    if (anterior != _original?.fotoPath) await MediaService().eliminarFoto(anterior);
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: DateTime(2000),
      lastDate: hoy,
    );
    if (f != null) {
      setState(() {
        _fecha = f;
        _fechaInvalida = false;
      });
    }
  }

  String? _validarEntero(String? v, {bool obligatorio = false}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return obligatorio ? 'Este dato es obligatorio' : null;
    final n = int.tryParse(t);
    return n == null || n <= 0 ? 'Ingresa un entero positivo' : null;
  }

  String? _texto(TextEditingController c, [bool aplica = true]) {
    final t = c.text.trim();
    return aplica && t.isNotEmpty ? t : null;
  }

  Future<void> _guardar() async {
    final valido = _formKey.currentState!.validate();
    if (_fecha == null) setState(() => _fechaInvalida = true);
    if (!valido || _fecha == null) return;

    final campos = _tipo.camposFicha;
    final equipo = Equipo(
      id: _original?.id,
      tipo: _tipo,
      nombre: _nombre.text.trim(),
      marca: _texto(_marca),
      modelo: _texto(_modelo),
      numeroSerie: _texto(_serie, campos.contains(CampoFicha.numeroSerie)),
      procesador: _texto(_procesador, campos.contains(CampoFicha.procesador)),
      ramGb: campos.contains(CampoFicha.ramGb) ? int.tryParse(_ram.text.trim()) : null,
      almacenamientoGb: campos.contains(CampoFicha.almacenamientoGb)
          ? int.tryParse(_almacenamiento.text.trim())
          : null,
      fechaCompra: _fecha!,
      fotoPath: _foto,
      notas: _texto(_notas),
      creadoEn: _original?.creadoEn ?? DateTime.now(),
    );
    setState(() => _guardando = true);
    try {
      final repo = EquipoRepository();
      if (_original == null) {
        await repo.insertar(equipo);
      } else {
        await repo.actualizar(equipo);
        if (_foto != _original!.fotoPath) {
          await MediaService().eliminarFoto(_original!.fotoPath);
        }
      }
      _guardado = true;
      if (mounted) Navigator.pop(context, true);
    } on DatabaseException {
      _error('No se pudo guardar el equipo en la base de datos');
    } catch (_) {
      _error('Ocurrió un error al guardar el equipo');
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _numero(TextEditingController c, String etiqueta, {bool obligatorio = false}) =>
      TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: etiqueta),
        validator: (v) => _validarEntero(v, obligatorio: obligatorio),
      );

  @override
  Widget build(BuildContext context) {
    final campos = _tipo.camposFicha;
    final editando = _original != null;
    const sep = SizedBox(height: 12);
    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar equipo' : 'Nuevo equipo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<TipoEquipo>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo de equipo'),
              items: [
                for (final t in TipoEquipo.values)
                  DropdownMenuItem(value: t, child: Text(t.etiqueta)),
              ],
              // Al editar el tipo no se puede cambiar.
              onChanged: editando ? null : (t) => setState(() => _tipo = t ?? _tipo),
            ),
            sep,
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'El nombre es obligatorio' : null,
            ),
            sep,
            TextFormField(
              controller: _marca,
              decoration: const InputDecoration(labelText: 'Marca'),
            ),
            sep,
            TextFormField(
              controller: _modelo,
              decoration: const InputDecoration(labelText: 'Modelo'),
            ),
            if (campos.contains(CampoFicha.numeroSerie)) ...[
              sep,
              TextFormField(
                controller: _serie,
                decoration: const InputDecoration(labelText: 'Número de serie'),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'El número de serie es obligatorio'
                    : null,
              ),
            ],
            if (campos.contains(CampoFicha.procesador)) ...[
              sep,
              TextFormField(
                controller: _procesador,
                decoration: const InputDecoration(labelText: 'Procesador'),
              ),
            ],
            if (campos.contains(CampoFicha.ramGb)) ...[sep, _numero(_ram, 'RAM (GB)')],
            if (campos.contains(CampoFicha.almacenamientoGb)) ...[
              sep,
              _numero(_almacenamiento, 'Almacenamiento total (GB)', obligatorio: true),
            ],
            sep,
            OutlinedButton.icon(
              onPressed: _elegirFecha,
              icon: const Icon(Icons.event),
              label: Text(_fecha == null
                  ? 'Fecha de compra'
                  : 'Compra: ${formatearFecha(_fecha!)}'),
            ),
            if (_fechaInvalida)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  'La fecha de compra es obligatoria',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error, fontSize: 12),
                ),
              ),
            sep,
            FotoPicker(
              fotoPath: _foto,
              onCambio: _cambiarFoto,
              iconoVacio: _tipo.icono,
            ),
            sep,
            CampoDictado(controller: _notas, etiqueta: 'Notas'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
