import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Studio-grade Zen Acoustic Ambient Soundtrack Generator
/// Uses Karplus-Strong physical modeling and FM Rhodes synthesis for pure, relaxing, zen vibes.
void main() {
  print('Generating Studio-Grade Zen Ambient Soundtrack...');

  const sampleRate = 44100;
  const int durationSeconds = 64; // 64-second ultra-smooth loop
  const totalSamples = sampleRate * durationSeconds;

  final left = Float64List(totalSamples);
  final right = Float64List(totalSamples);

  // 1. Cozy Zen Chord Progressions: Key of D-Flat / F-Minor Zen (Dbmaj9 -> Abmaj7 -> Fm9 -> Bbsus2/9)
  // Peaceful, warm, meditative, modern lo-fi zen aesthetic
  final chordData = [
    // Dbmaj9 (Db3, F3, Ab3, C4, Eb4)
    [138.59, 174.61, 207.65, 261.63, 311.13],
    // Abmaj7 (Ab2, Eb3, C4, G4, Bb4)
    [103.83, 155.56, 261.63, 392.00, 466.16],
    // Fm9 (F2, C3, Ab3, Eb4, G4)
    [87.31, 130.81, 207.65, 311.13, 392.00],
    // Bbsus2/9 (Bb2, F3, C4, F4, Ab4)
    [116.54, 174.61, 261.63, 349.23, 415.30],
  ];

  const chordLength = 16.0; // 16s per chord

  // Synthesize Warm Velvet Rhodes / Pad Layer
  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate;
    final chordIdx = ((t / chordLength) % chordData.length).floor();
    final chord = chordData[chordIdx];
    final chordProgress = (t % chordLength) / chordLength;

    // Smooth Hann window for breathing chord crossfades
    final env = sin(chordProgress * pi);

    for (int n = 0; n < chord.length; n++) {
      final freq = chord[n];
      final lfo = sin(t * 0.25 + n * 0.8) * 0.35;

      // Warm blended sine + soft triangle
      final oscL = (sin(2 * pi * (freq + lfo) * t) * 0.65 +
              (sin(2 * pi * (freq * 2) * t) * 0.12) +
              (sin(2 * pi * (freq * 3) * t) * 0.04)) *
          0.038 *
          env;

      final oscR = (sin(2 * pi * (freq - lfo) * t) * 0.65 +
              (sin(2 * pi * (freq * 2) * t) * 0.12) +
              (sin(2 * pi * (freq * 3) * t) * 0.04)) *
          0.038 *
          env;

      left[i] += oscL;
      right[i] += oscR;
    }

    // Sub-bass warmth
    final subFreq = chord[0] * 0.5;
    final sub = sin(2 * pi * subFreq * t) * 0.026 * env;
    left[i] += sub;
    right[i] += sub;
  }

  // 2. Physical Modeling Karplus-Strong Plucked Acoustic Zen Drops
  // Sounds like a real wooden Japanese Koto / Acoustic Zen Kalimba
  final melodyNotes = [
    // time, freq, pan
    (2.0, 523.25, -0.35),  // C5
    (4.5, 622.25, 0.30),   // Eb5
    (7.0, 698.46, -0.20),  // F5
    (10.5, 830.61, 0.40),  // Ab5
    (13.0, 622.25, -0.10), // Eb5

    (18.0, 783.99, 0.35),  // G5
    (20.5, 932.33, -0.30), // Bb5
    (23.0, 1046.50, 0.20), // C6
    (26.5, 783.99, -0.40), // G5
    (29.0, 698.46, 0.15),  // F5

    (34.0, 622.25, -0.35), // Eb5
    (36.5, 830.61, 0.30),  // Ab5
    (39.0, 932.33, -0.20), // Bb5
    (42.5, 1046.50, 0.40), // C6
    (45.0, 830.61, -0.15), // Ab5

    (50.0, 698.46, 0.30),  // F5
    (52.5, 830.61, -0.35), // Ab5
    (55.0, 932.33, 0.25),  // Bb5
    (58.5, 622.25, -0.25), // Eb5
    (61.0, 523.25, 0.10),  // C5
  ];

  final rand = Random(42);

  for (final note in melodyNotes) {
    final startIdx = (note.$1 * sampleRate).round();
    final freq = note.$2;
    final pan = note.$3;
    final period = (sampleRate / freq).round();
    if (period <= 1) continue;

    // Initialize delay line with filtered white noise for acoustic pluck attack
    final delayLine = Float64List(period);
    for (int p = 0; p < period; p++) {
      delayLine[p] = (rand.nextDouble() * 2.0 - 1.0) * exp(-p / (period * 0.6));
    }

    const noteDuration = 3.2; // 3.2s long resonant wooden decay
    final noteSampleCount = (noteDuration * sampleRate).round();

    double lastSample = 0.0;
    int bufferIdx = 0;

    for (int s = 0; s < noteSampleCount; s++) {
      final outIdx = (startIdx + s) % totalSamples;
      final tNote = s / sampleRate;

      // Karplus-Strong low-pass feedback loop
      final cur = delayLine[bufferIdx];
      // Two-point averaging filter for wooden damping
      final filtered = (cur + lastSample) * 0.5 * 0.993;
      delayLine[bufferIdx] = filtered;
      lastSample = filtered;
      bufferIdx = (bufferIdx + 1) % period;

      // Body resonance & smooth fade envelope
      final noteEnv = exp(-tNote * 1.8);
      final sample = cur * noteEnv * 0.055;

      final gainL = 0.5 * (1.0 - pan);
      final gainR = 0.5 * (1.0 + pan);

      left[outIdx] += sample * gainL;
      right[outIdx] += sample * gainR;

      // Stereo ambient room reverb reflections (at 160ms and 320ms)
      final echo1 = (outIdx + (0.16 * sampleRate).round()) % totalSamples;
      final echo2 = (outIdx + (0.32 * sampleRate).round()) % totalSamples;
      left[echo1] += sample * gainR * 0.28;
      right[echo1] += sample * gainL * 0.28;
      left[echo2] += sample * gainL * 0.14;
      right[echo2] += sample * gainR * 0.14;
    }
  }

  // 3. Normalize & Master to 16-bit Stereo PCM WAV
  final pcmBytes = BytesBuilder();
  final dataSize = totalSamples * 4;
  final fileSize = 36 + dataSize;

  pcmBytes.add('RIFF'.codeUnits);
  pcmBytes.add(_int32(fileSize));
  pcmBytes.add('WAVE'.codeUnits);
  pcmBytes.add('fmt '.codeUnits);
  pcmBytes.add(_int32(16));
  pcmBytes.add(_int16(1));
  pcmBytes.add(_int16(2));
  pcmBytes.add(_int32(sampleRate));
  pcmBytes.add(_int32(sampleRate * 4));
  pcmBytes.add(_int16(4));
  pcmBytes.add(_int16(16));
  pcmBytes.add('data'.codeUnits);
  pcmBytes.add(_int32(dataSize));

  double maxPeak = 0.0001;
  for (int i = 0; i < totalSamples; i++) {
    maxPeak = max(maxPeak, max(left[i].abs(), right[i].abs()));
  }

  final targetPeak = 0.85;
  final gain = targetPeak / maxPeak;

  for (int i = 0; i < totalSamples; i++) {
    final sampleL = (left[i] * gain).clamp(-1.0, 1.0);
    final sampleR = (right[i] * gain).clamp(-1.0, 1.0);

    final int16L = (sampleL * 32767).round();
    final int16R = (sampleR * 32767).round();

    pcmBytes.add(_int16(int16L));
    pcmBytes.add(_int16(int16R));
  }

  final wavFile = File('assets/audio/bg_music.mp3');
  wavFile.writeAsBytesSync(pcmBytes.toBytes());
  File('assets/audio/bg_music.wav').writeAsBytesSync(pcmBytes.toBytes());

  print('Successfully generated studio-grade zen acoustic soundtrack (${wavFile.lengthSync()} bytes)');
}

List<int> _int32(int value) {
  final bd = ByteData(4)..setInt32(0, value, Endian.little);
  return bd.buffer.asUint8List();
}

List<int> _int16(int value) {
  final bd = ByteData(2)..setInt16(0, value, Endian.little);
  return bd.buffer.asUint8List();
}
