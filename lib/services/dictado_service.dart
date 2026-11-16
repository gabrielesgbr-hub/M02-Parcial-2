import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

// Envoltura de speech_to_text. Singleton porque el plugin solo admite una sesión a la vez.
class DictadoService {
  static final DictadoService instance = DictadoService._init();

  DictadoService._init();

  final SpeechToText _stt = SpeechToText();
  Future<bool>? _init; // se cachea para inicializar una sola vez
  String? _localeId;
  void Function()? _onFin;
  bool _activa = false; // la sesión actual ya confirmó que escucha y no ha terminado

  bool get escuchando => _stt.isListening;

  // false si no hay permiso de micrófono o el reconocedor no está disponible.
  Future<bool> inicializar() => _init ??= _inicializar();

  Future<bool> _inicializar() async {
    try {
      final ok = await _stt.initialize(
        onStatus: (s) {
          if (s == SpeechToText.listeningStatus) {
            _activa = true;
          } else if (_activa &&
              (s == SpeechToText.doneStatus ||
                  s == SpeechToText.notListeningStatus)) {
            _terminar(); // los avisos tardíos de una sesión detenida se ignoran
          }
        },
        onError: (e) {
          debugPrint('Error de dictado: ${e.errorMsg}');
          _terminar();
        },
      );
      if (ok) {
        _localeId = await _elegirLocale();
      } else {
        _init = null; // permite reintentar si negaron el permiso
      }
      return ok;
    } catch (e, st) {
      debugPrint('No se pudo inicializar el dictado: $e\n$st');
      _init = null;
      return false;
    }
  }

  Future<String?> _elegirLocale() async {
    final locales = await _stt.locales();
    for (final l in locales) {
      if (l.localeId.replaceAll('-', '_') == 'es_MX') return l.localeId;
    }
    for (final l in locales) {
      if (l.localeId.startsWith('es')) return l.localeId;
    }
    return (await _stt.systemLocale())?.localeId;
  }

  void _terminar() {
    _activa = false;
    final cb = _onFin;
    _onFin = null;
    cb?.call();
  }

  Future<void> escuchar({
    required void Function(String texto, bool esFinal) onResultado,
    void Function()? onFin,
  }) async {
    _onFin = onFin;
    _activa = false;
    await _stt.listen(
      onResult: (r) => onResultado(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: _localeId,
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
    );
  }

  // Avisa el fin en el momento para no depender del estado que llega después.
  Future<void> detener() {
    _terminar();
    return _stt.stop();
  }
}
