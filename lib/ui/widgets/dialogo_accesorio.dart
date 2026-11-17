import 'package:material_ui/material_ui.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/accesorio_repository.dart';
import '../../models/accesorio.dart';
import '../../models/equipo.dart';
import '../../models/tipo_equipo.dart';
import '../../utils/fechas.dart';
import 'campo_dictado.dart';

// Crear (accesorio == null) o editar un accesorio. Devuelve true si guardó.
Future<bool?> mostrarDialogoAccesorio(
  BuildContext context, {
  required Equipo equipo,
  Accesorio? accesorio,
}) => showDialog<bool>(
  context: context,
  builder: (_) => _DialogoAccesorio(equipo: equipo, accesorio: accesorio),
);

class _DialogoAccesorio extends StatefulWidget {
  const _DialogoAccesorio({required this.equipo, this.accesorio});

  final Equipo equipo;
  final Accesorio? accesorio;

  @override
  State<_DialogoAccesorio> createState() => _DialogoAccesorioState();
}

class _DialogoAccesorioState extends State<_DialogoAccesorio> {
  late final _descripcion = TextEditingController(
    text: widget.accesorio?.descripcion ?? '',
  );
  late TipoAccesorio _tipo =
      widget.accesorio?.tipo ?? widget.equipo.tipo.accesorios.first;
  late DateTime? _fecha = widget.accesorio?.fechaCompra;
  late EstadoAccesorio _estado =
      widget.accesorio?.estado ?? EstadoAccesorio.bueno;
  bool _guardando = false;

  @override
  void dispose() {
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      firstDate: DateTime(2000),
      lastDate: hoy,
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _guardar() async {
    final desc = _descripcion.text.trim();
    final nuevo = Accesorio(
      id: widget.accesorio?.id,
      equipoId: widget.equipo.id!,
      tipo: _tipo,
      descripcion: desc.isEmpty ? null : desc,
      fechaCompra: _fecha,
      estado: _estado,
    );
    setState(() => _guardando = true);
    final repo = AccesorioRepository();
    try {
      if (widget.accesorio == null) {
        await repo.insertar(nuevo);
      } else {
        await repo.actualizar(nuevo);
      }
      if (mounted) Navigator.pop(context, true);
    } on DatabaseException {
      _error('No se pudo guardar el accesorio en la base de datos');
    } catch (_) {
      _error('Ocurrió un error al guardar el accesorio');
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    setState(() => _guardando = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.accesorio == null ? 'Nuevo accesorio' : 'Editar accesorio',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<TipoAccesorio>(
              initialValue: _tipo,
              isExpanded: true,
              // Alto máximo: si no caben las opciones, el menú se desplaza.
              menuMaxHeight: MediaQuery.sizeOf(context).height * 0.4,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final t in widget.equipo.tipo.accesorios)
                  DropdownMenuItem(value: t, child: Text(t.etiqueta)),
              ],
              onChanged: (t) => setState(() => _tipo = t ?? _tipo),
            ),
            const SizedBox(height: 12),
            CampoDictado(
              controller: _descripcion,
              etiqueta: 'Descripción',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _elegirFecha,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _fecha == null
                          ? 'Fecha de compra'
                          : formatearFecha(_fecha!),
                    ),
                  ),
                ),
                if (_fecha != null)
                  IconButton(
                    tooltip: 'Quitar fecha',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _fecha = null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Estado'),
            const SizedBox(height: 4),
            // Chips en Wrap: en diálogos angostos bajan de línea en vez de desbordarse.
            Wrap(
              spacing: 8,
              children: [
                for (final e in EstadoAccesorio.values)
                  ChoiceChip(
                    label: Text(e.etiqueta),
                    selected: _estado == e,
                    onSelected: (_) => setState(() => _estado = e),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
