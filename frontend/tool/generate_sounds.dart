// Generates the app's UI sound effects into assets/sounds/.
//
//   dart run tool/generate_sounds.dart
//
// Every sound is synthesized here (no third-party audio), so the files are
// reproducible and license-free. Keep them short, soft, and calm: AIBS is a
// health app, so feedback should feel friendly, never alarming.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _rate = 22050;

void main() {
  final out = Directory('assets/sounds')..createSync(recursive: true);
  final sounds = <String, List<double>>{
    'tap': _tap(),
    'success': _success(),
    'notice': _notice(),
    'koala': _koala(),
    'pop': _pop(),
  };
  sounds.forEach((name, samples) {
    final file = File('${out.path}/$name.wav');
    file.writeAsBytesSync(_wav(samples));
    stdout.writeln('${file.path}  ${file.lengthSync()} bytes');
  });
}

/// Soft, short "tick" for every button press.
List<double> _tap() {
  return _render(0.045, (t) {
    final f = 1250 - 3000 * t; // slight downward chirp
    final env = _attack(t, 0.002) * math.exp(-t / 0.009);
    return 0.45 * env * _tone(f, t, h2: 0.15);
  });
}

/// Rising three-note chime when something is saved.
List<double> _success() {
  const notes = [1046.5, 1318.5, 1568.0]; // C6 E6 G6
  return _render(0.65, (t) {
    var v = 0.0;
    for (var i = 0; i < notes.length; i++) {
      final start = i * 0.075;
      if (t < start) continue;
      final lt = t - start;
      final env = _attack(lt, 0.004) * math.exp(-lt / 0.16);
      v += env * _tone(notes[i], lt, h2: 0.3, h3: 0.08);
    }
    return 0.28 * v;
  });
}

/// Gentle two-note "hmm" for errors and reminders.
List<double> _notice() {
  return _render(0.36, (t) {
    var v = 0.0;
    for (final (start, f) in [(0.0, 523.25), (0.12, 415.3)]) {
      if (t < start) continue;
      final lt = t - start;
      final env = _attack(lt, 0.006) * math.exp(-lt / 0.07);
      v += env * _tone(f, lt, h3: 0.18);
    }
    return 0.42 * v;
  });
}

/// Cute "boing" when the koala is poked.
List<double> _koala() {
  const dur = 0.26;
  var phase = 0.0;
  final samples = <double>[];
  for (var i = 0; i < (dur * _rate).round(); i++) {
    final t = i / _rate;
    final f = t < 0.09
        ? 480 + (1000 - 480) * _easeOut(t / 0.09)
        : 1000 - 260 * _easeOut((t - 0.09) / (dur - 0.09));
    final vibrato = 1 + 0.035 * math.sin(2 * math.pi * 28 * t);
    phase += 2 * math.pi * f * vibrato / _rate;
    final env = _attack(t, 0.008) * math.exp(-t / 0.09);
    samples.add(0.42 * env * (math.sin(phase) + 0.18 * math.sin(2 * phase)));
  }
  return samples;
}

/// Light bubble pop for small selections (chips, toggles).
List<double> _pop() {
  var phase = 0.0;
  return _render(0.07, (t) {
    final f = 700 + 1100 * _easeOut(t / 0.07);
    phase += 2 * math.pi * f / _rate;
    final env = _attack(t, 0.002) * math.exp(-t / 0.018);
    return 0.4 * env * math.sin(phase);
  });
}

// ---------------------------------------------------------------------------

double _tone(double f, double t, {double h2 = 0, double h3 = 0}) {
  final w = 2 * math.pi * f * t;
  return math.sin(w) + h2 * math.sin(2 * w) + h3 * math.sin(3 * w);
}

double _attack(double t, double seconds) => t >= seconds ? 1 : t / seconds;

double _easeOut(double x) {
  final c = x.clamp(0.0, 1.0);
  return 1 - (1 - c) * (1 - c);
}

List<double> _render(double seconds, double Function(double t) fn) {
  final n = (seconds * _rate).round();
  final fade = (0.004 * _rate).round(); // avoid a click at the very end
  return List.generate(n, (i) {
    final tail = n - i < fade ? (n - i) / fade : 1.0;
    return fn(i / _rate) * tail;
  });
}

Uint8List _wav(List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, _rate, Endian.little);
  data.setUint32(28, _rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + i * 2, v, Endian.little);
  }
  return data.buffer.asUint8List();
}
