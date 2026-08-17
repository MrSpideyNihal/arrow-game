import 'package:web/web.dart' as web;

class WebAudioSynth {
  web.AudioContext? _ctx;

  void init() {
    try {
      _ctx = web.AudioContext();
    } catch (_) {}
  }

  void ensureResumed() {
    try {
      if (_ctx != null && _ctx!.state == 'suspended') {
        _ctx!.resume();
      }
    } catch (_) {}
  }

  web.AudioContext? get ctx => _ctx;
}
