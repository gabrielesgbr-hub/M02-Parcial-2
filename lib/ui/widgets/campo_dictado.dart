import 'package:material_ui/material_ui.dart';

import '../../services/dictado_service.dart';

// TextFormField multilínea con botón de micrófono; el texto dictado se agrega al existente.
class CampoDictado extends StatefulWidget {
  const CampoDictado({
    super.key,
    required this.controller,
    required this.etiqueta,
    this.maxLines = 3,
    this.validator,
  });

  final TextEditingController controller;
  final String etiqueta;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  State<CampoDictado> createState() => _CampoDictadoState();
}

class _CampoDictadoState extends State<CampoDictado> {
  final _dictado = DictadoService.instance;
  bool _escuchando = false;

  @override
  void dispose() {
    if (_escuchando) _dictado.detener();
    super.dispose();
  }

  Future<void> _alternar() async {
    if (_escuchando) {
      await _dictado.detener();
      return;
    }
    // Solo un campo a la vez: se detiene cualquier sesión previa.
    if (_dictado.escuchando) await _dictado.detener();

    final ok = await _dictado.inicializar();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Dictado no disponible: revisa el permiso del micrófono'),
        ),
      );
      return;
    }

    final base = widget.controller.text.trimRight();
    setState(() => _escuchando = true);
    try {
      await _dictado.escuchar(
        onResultado: (texto, esFinal) {
          if (!mounted) return;
          final nuevo = base + (base.isEmpty ? '' : ' ') + texto;
          widget.controller.value = TextEditingValue(
            text: nuevo,
            selection: TextSelection.collapsed(offset: nuevo.length),
          );
        },
        onFin: () {
          if (mounted) setState(() => _escuchando = false);
        },
      );
    } catch (e) {
      debugPrint('Error al dictar: $e');
      if (!mounted) return;
      setState(() => _escuchando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar el dictado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        suffixIcon: IconButton(
          tooltip: _escuchando ? 'Detener dictado' : 'Dictar',
          icon: Icon(_escuchando ? Icons.stop_circle : Icons.mic),
          color: _escuchando ? Theme.of(context).colorScheme.error : null,
          onPressed: _alternar,
        ),
      ),
    );
  }
}
