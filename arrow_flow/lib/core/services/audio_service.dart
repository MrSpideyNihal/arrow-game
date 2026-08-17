import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

import 'audio_service_stub.dart'
    if (dart.library.js_interop) 'audio_service_web.dart';

/// High-performance Audio Service providing zero-latency sound effects & music.
/// Supports both asset playback and Web Audio API procedural sound synthesis.
///
/// Sound Design Philosophy: "Satisfying & Chill"
/// - Arrow remove: Satisfying pop with harmonic overtone
/// - Wrong tap: Quick buzzy "nope" sound, not annoying
/// - Combo tier: Rising melodic arpeggio (bright, rewarding)
/// - Level complete: Triumphant celebration fanfare
/// - Timer tick: Subtle clock tick, urgent beep when low
/// - BG Music: Ambient chill lo-fi loop (synthesized)
class AudioService {
  static AudioService? _instance;

  static void init({required AudioConfig config}) {
    _instance ??= AudioService._internal(config);
  }

  factory AudioService({required AudioConfig config}) {
    _instance ??= AudioService._internal(config);
    return _instance!;
  }

  AudioService._internal(this.config) {
    final storage = StorageService();
    _sfxEnabled =
        storage.getSetting<bool>('sfx_enabled', defaultValue: config.sfxEnabledDefault) ??
            config.sfxEnabledDefault;
    _musicEnabled =
        storage.getSetting<bool>('music_enabled', defaultValue: config.musicEnabledDefault) ??
            config.musicEnabledDefault;
    _configureAudioContexts();
    _initWebAudio();
  }

  final AudioConfig config;
  late bool _sfxEnabled;
  late bool _musicEnabled;
  bool _musicStarted = false;
  Timer? _musicLoopTimer;

  // Player pool for overlapping SFX
  static final List<AudioPlayer> _sfxPool = List.generate(4, (_) => AudioPlayer());
  static int _sfxPoolIdx = 0;
  static final AudioPlayer _musicPlayer = AudioPlayer();

  static void _configureAudioContexts() {
    try {
      final musicContext = AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      );
      AudioPlayer.global.setAudioContext(musicContext);
      _musicPlayer.setAudioContext(musicContext);

      final sfxContext = AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      );
      for (final player in _sfxPool) {
        player.setAudioContext(sfxContext);
      }
    } catch (e) {
      debugPrint('AudioContext config: $e');
    }
  }

  // Web Audio Context reference
  final WebAudioSynth _webAudio = WebAudioSynth();

  void _initWebAudio() {
    if (kIsWeb) {
      _webAudio.init();
    }
  }

  void _ensureWebAudioResumed() {
    if (kIsWeb) {
      _webAudio.ensureResumed();
    }
  }

  bool get isSfxEnabled => _sfxEnabled;
  bool get isMusicEnabled => _musicEnabled;

  Future<void> toggleSfx(bool enabled) async {
    _sfxEnabled = enabled;
    await StorageService().saveSetting('sfx_enabled', enabled);
  }

  Future<void> toggleMusic(bool enabled) async {
    _musicEnabled = enabled;
    await StorageService().saveSetting('music_enabled', enabled);
    if (!enabled) {
      await _musicPlayer.stop();
      _musicLoopTimer?.cancel();
      _musicStarted = false;
    } else {
      await playMusic();
    }
  }

  Future<void> playMusic() async {
    if (!_musicEnabled) return;
    _ensureWebAudioResumed();

    // On web, use synthesized ambient music instead of asset
    if (kIsWeb && _webAudio.ctx != null) {
      _startAmbientMusicLoop();
      return;
    }

    try {
      if (_musicPlayer.state == PlayerState.playing) {
        return;
      }
      if (_musicPlayer.state == PlayerState.paused) {
        await _musicPlayer.resume();
        _musicStarted = true;
        return;
      }
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0.55);
      await _musicPlayer.play(AssetSource('audio/bg_music.mp3'));
      _musicStarted = true;
    } catch (e) {
      debugPrint('AudioService playMusic error: $e');
    }
  }

  Future<void> onFirstInteraction() async {
    _ensureWebAudioResumed();
    if (!_musicStarted && _musicEnabled) {
      await playMusic();
    }
  }

  Future<void> stopMusic() async {
    _musicLoopTimer?.cancel();
    _musicStarted = false;
    try {
      await _musicPlayer.stop();
    } catch (_) {}
  }

  /// Play tap sound (light crisp click for invalid tap)
  Future<void> playTap() async {
    if (!_sfxEnabled) return;
    _ensureWebAudioResumed();
    if (kIsWeb && _webAudio.ctx != null) {
      _synthErrorBuzz();
      return;
    }
    _playAsset('audio/sfx_tap.wav');
  }

  /// Play arrow remove sound (satisfying pop with harmonic chime, pitch-scaled by combo streak)
  Future<void> playRemove({int comboCount = 0}) async {
    if (!_sfxEnabled) return;
    _ensureWebAudioResumed();
    if (kIsWeb && _webAudio.ctx != null) {
      _synthSatisfyingPop(comboCount: comboCount);
      return;
    }
    _playAsset('audio/sfx_remove.wav');
  }

  /// Play bomb explosion blast sound
  Future<void> playBombBlast() async {
    if (!_sfxEnabled) return;
    _ensureWebAudioResumed();
    if (kIsWeb && _webAudio.ctx != null) {
      _synthBombBlast();
      return;
    }
  }

  /// Play radar scan sweep sound
  Future<void> playRadarSweep() async {
    if (!_sfxEnabled) return;
    _ensureWebAudioResumed();
    if (kIsWeb && _webAudio.ctx != null) {
      _synthRadarSweep();
      return;
    }
  }

  /// Play combo tier sound (melodic ascending arpeggio)
  Future<void> playComboTier() async {
    if (!_sfxEnabled) return;
    _ensureWebAudioResumed();
    if (kIsWeb && _webAudio.ctx != null) {
      _synthComboArpeggio();
      return;
    }
    _playAsset('audio/sfx_combo_tier.wav');
  }

  /// Play timer tick sound
  Future<void> playTick({bool isUrgent = false}) async {
    if (!_sfxEnabled) return;
    _ensureWebAudioResumed();
    if (kIsWeb && _webAudio.ctx != null) {
      _synthTimerTick(isUrgent: isUrgent);
      return;
    }
  }

  /// Play level complete fanfare
  Future<void> playLevelComplete() async {
    if (!_sfxEnabled) return;
    _ensureWebAudioResumed();
    if (kIsWeb && _webAudio.ctx != null) {
      _synthVictoryFanfare();
      return;
    }
    _playAsset('audio/sfx_level_complete.wav');
  }

  void _playAsset(String path) {
    try {
      final player = _sfxPool[_sfxPoolIdx];
      _sfxPoolIdx = (_sfxPoolIdx + 1) % _sfxPool.length;
      player.stop();
      player.play(AssetSource(path));
    } catch (_) {}
  }

  // ───────────────────── Web Audio API — Premium Sound Synth ─────────────────────

  /// Satisfying pop sound for arrow removal — pentatonic musical progression with combo!
  void _synthSatisfyingPop({int comboCount = 0}) {
    try {
      final ctx = _webAudio.ctx;
      if (ctx == null) return;
      final now = ctx.currentTime;

      // Pentatonic pitch scale: C4, D4, E4, G4, A4, C5, D5, E5, G5, A5
      const scale = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25, 783.99, 880.00];
      final pitchIdx = comboCount > 0 ? (comboCount - 1) % scale.length : 0;
      final baseFreq = scale[pitchIdx];

      // Main chime: sine with smooth frequency envelope
      final osc1 = ctx.createOscillator();
      final gain1 = ctx.createGain();
      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(baseFreq * 0.9, now);
      osc1.frequency.exponentialRampToValueAtTime(baseFreq * 1.5, now + 0.05);
      osc1.frequency.exponentialRampToValueAtTime(baseFreq, now + 0.12);
      gain1.gain.setValueAtTime(0.35, now);
      gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.16);
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start(now);
      osc1.stop(now + 0.18);

      // Harmonic overtone: bright chime
      final osc2 = ctx.createOscillator();
      final gain2 = ctx.createGain();
      osc2.type = 'triangle';
      osc2.frequency.setValueAtTime(baseFreq * 2.0, now);
      osc2.frequency.exponentialRampToValueAtTime(baseFreq * 2.5, now + 0.04);
      gain2.gain.setValueAtTime(0.18, now);
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.12);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(now);
      osc2.stop(now + 0.14);
    } catch (_) {}
  }

  /// Powerful punchy bomb blast explosion synth
  void _synthBombBlast() {
    try {
      final ctx = _webAudio.ctx;
      if (ctx == null) return;
      final now = ctx.currentTime;

      // Low sub bass boom
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(160, now);
      osc.frequency.exponentialRampToValueAtTime(30, now + 0.35);
      gain.gain.setValueAtTime(0.5, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.4);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.42);

      // Crackle impact
      final osc2 = ctx.createOscillator();
      final gain2 = ctx.createGain();
      osc2.type = 'sawtooth';
      osc2.frequency.setValueAtTime(300, now);
      osc2.frequency.exponentialRampToValueAtTime(40, now + 0.15);
      gain2.gain.setValueAtTime(0.3, now);
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.18);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(now);
      osc2.stop(now + 0.2);
    } catch (_) {}
  }

  /// High-tech radar scan sweep synth
  void _synthRadarSweep() {
    try {
      final ctx = _webAudio.ctx;
      if (ctx == null) return;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(520, now);
      osc.frequency.exponentialRampToValueAtTime(1040, now + 0.15);
      osc.frequency.exponentialRampToValueAtTime(1560, now + 0.3);
      gain.gain.setValueAtTime(0.2, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.38);
    } catch (_) {}
  }

  /// Error buzz for wrong tap — quick short "nope" without being annoying
  void _synthErrorBuzz() {
    try {
      final ctx = _webAudio.ctx;
      if (ctx == null) return;
      final now = ctx.currentTime;

      // Low buzz
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(180, now);
      osc.frequency.exponentialRampToValueAtTime(120, now + 0.08);
      gain.gain.setValueAtTime(0.18, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now);
      osc.stop(now + 0.12);

      // Click on top
      final osc2 = ctx.createOscillator();
      final gain2 = ctx.createGain();
      osc2.type = 'square';
      osc2.frequency.setValueAtTime(90, now);
      gain2.gain.setValueAtTime(0.12, now);
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.05);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(now);
      osc2.stop(now + 0.06);
    } catch (_) {}
  }

  /// Combo tier arpeggio — bright ascending notes with sparkle
  void _synthComboArpeggio() {
    try {
      final ctx = _webAudio.ctx;
      if (ctx == null) return;
      final now = ctx.currentTime;

      // C major arpeggio with sparkle: C5 → E5 → G5 → C6
      final notes = [523.25, 659.25, 783.99, 1046.50];

      for (int i = 0; i < notes.length; i++) {
        final startTime = now + i * 0.07;

        // Main tone
        final osc = ctx.createOscillator();
        final gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(notes[i], startTime);
        gain.gain.setValueAtTime(0.28, startTime);
        gain.gain.exponentialRampToValueAtTime(0.001, startTime + 0.25);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(startTime);
        osc.stop(startTime + 0.27);

        // Sparkle overtone (2 octaves up, quiet)
        final osc2 = ctx.createOscillator();
        final gain2 = ctx.createGain();
        osc2.type = 'sine';
        osc2.frequency.setValueAtTime(notes[i] * 4, startTime);
        gain2.gain.setValueAtTime(0.06, startTime);
        gain2.gain.exponentialRampToValueAtTime(0.001, startTime + 0.12);
        osc2.connect(gain2);
        gain2.connect(ctx.destination);
        osc2.start(startTime);
        osc2.stop(startTime + 0.14);
      }
    } catch (_) {}
  }

  /// Timer tick — subtle click, urgent beep when low
  void _synthTimerTick({bool isUrgent = false}) {
    try {
      final ctx = _webAudio.ctx;
      if (ctx == null) return;
      final now = ctx.currentTime;

      if (isUrgent) {
        // Urgent: short high-pitched double beep
        for (int i = 0; i < 2; i++) {
          final osc = ctx.createOscillator();
          final gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(1200, now + i * 0.08);
          gain.gain.setValueAtTime(0.2, now + i * 0.08);
          gain.gain.exponentialRampToValueAtTime(0.001, now + i * 0.08 + 0.04);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start(now + i * 0.08);
          osc.stop(now + i * 0.08 + 0.05);
        }
      } else {
        // Normal: subtle wooden click
        final osc = ctx.createOscillator();
        final gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(800, now);
        osc.frequency.exponentialRampToValueAtTime(400, now + 0.02);
        gain.gain.setValueAtTime(0.12, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.04);
      }
    } catch (_) {}
  }

  /// Victory fanfare for level complete — triumphant chord progression
  void _synthVictoryFanfare() {
    try {
      final ctx = _webAudio.ctx;
      if (ctx == null) return;
      final now = ctx.currentTime;

      // Phase 1: Rising arpeggio C5 → E5 → G5
      final rise = [523.25, 659.25, 783.99];
      for (int i = 0; i < rise.length; i++) {
        final t = now + i * 0.1;
        final osc = ctx.createOscillator();
        final gain = ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(rise[i], t);
        gain.gain.setValueAtTime(0.3, t);
        gain.gain.exponentialRampToValueAtTime(0.001, t + 0.18);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(t);
        osc.stop(t + 0.2);
      }

      // Phase 2: Triumphant sustained chord C5+E5+G5+C6
      final chordTime = now + 0.35;
      final chord = [523.25, 659.25, 783.99, 1046.50];
      for (int i = 0; i < chord.length; i++) {
        final osc = ctx.createOscillator();
        final gain = ctx.createGain();
        osc.type = i == 3 ? 'sine' : 'triangle';
        osc.frequency.setValueAtTime(chord[i], chordTime);
        gain.gain.setValueAtTime(i == 3 ? 0.35 : 0.2, chordTime);
        gain.gain.exponentialRampToValueAtTime(0.001, chordTime + 0.6);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(chordTime);
        osc.stop(chordTime + 0.65);
      }

      // Phase 3: Final high sparkle
      final sparkle = now + 0.8;
      final osc = ctx.createOscillator();
      final gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(2093.0, sparkle); // C7
      gain.gain.setValueAtTime(0.15, sparkle);
      gain.gain.exponentialRampToValueAtTime(0.001, sparkle + 0.4);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(sparkle);
      osc.stop(sparkle + 0.45);
    } catch (_) {}
  }

  // ───────────────────── Ambient Chill Playful Zen Music Loop ─────────────────────

  /// Synthesized gentle playful zen music loop.
  /// Uses soft pentatonic kalimba / music box bell tones for a relaxing, playful vibe.
  void _startAmbientMusicLoop() {
    if (_musicStarted) return;
    _musicStarted = true;
    _playAmbientChord();

    // Repeat every 10 seconds for a soft, unobtrusive background ambient
    _musicLoopTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_musicEnabled && _musicStarted) {
        _playAmbientChord();
      }
    });
  }

  void _playAmbientChord() {
    try {
      final ctx = _webAudio.ctx;
      if (ctx == null) return;
      final now = ctx.currentTime;

      // Soft warm minty pad: Fmaj9 / Cmaj9 (F3, A3, C4, E4, G4)
      final padNotes = [174.61, 220.0, 261.63, 329.63, 392.0];

      for (int i = 0; i < padNotes.length; i++) {
        final osc = ctx.createOscillator();
        final gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(padNotes[i], now);

        // Ultra soft, gentle breathe in and out
        gain.gain.setValueAtTime(0.0, now);
        gain.gain.linearRampToValueAtTime(0.025, now + 1.5);
        gain.gain.linearRampToValueAtTime(0.02, now + 6.0);
        gain.gain.linearRampToValueAtTime(0.0, now + 9.5);

        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 10.0);
      }

      // Gentle playful kalimba drops (C5, G5, E5, D5, A5)
      final bellNotes = [523.25, 783.99, 659.25, 587.33, 880.0];
      for (int i = 0; i < bellNotes.length; i++) {
        final t = now + 1.2 + (i * 1.4);
        final osc = ctx.createOscillator();
        final gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(bellNotes[i], t);

        // Soft music box bell pluck
        gain.gain.setValueAtTime(0.0, t);
        gain.gain.linearRampToValueAtTime(0.035, t + 0.05);
        gain.gain.exponentialRampToValueAtTime(0.0005, t + 1.2);

        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(t);
        osc.stop(t + 1.3);
      }
    } catch (_) {}
  }

  void dispose() {
    _musicLoopTimer?.cancel();
  }
}
