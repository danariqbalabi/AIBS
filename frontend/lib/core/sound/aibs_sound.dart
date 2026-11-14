// UI sound effects.
//
//   AibsSound.play(AibsSfx.success);
//
// Button taps are played automatically by [AibsTapSounds] (wrapped around the
// whole app), so call [play] only for events: saved, error, koala poke.
// Sounds mix with the user's music (no audio focus) and respect the iOS
// silent switch. Users can mute them from Profil.

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AibsSfx {
  tap(0.55),
  pop(0.6),
  success(0.7),
  notice(0.6),
  koala(0.75);

  const AibsSfx(this.volume);
  final double volume;

  String get asset => 'sounds/$name.wav';
}

abstract final class AibsSound {
  /// Global switch. Tests turn this off (test/flutter_test_config.dart) so no
  /// platform audio channel is touched.
  static bool enabled = true;

  /// User preference, persisted. Listen to rebuild a toggle.
  static final ValueNotifier<bool> muted = ValueNotifier(false);

  static const _prefsKey = 'aibs.sound.muted';
  static const _voices = 3; // overlapping plays per sound
  static final Map<AibsSfx, List<AudioPlayer>> _players = {};
  static final Map<AibsSfx, int> _next = {};
  static final Map<AibsSfx, DateTime> _last = {};
  static bool _configured = false;

  /// Loads the mute preference. Safe to call more than once.
  static Future<void> init() async {
    if (!enabled) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      muted.value = prefs.getBool(_prefsKey) ?? false;
    } catch (_) {
      // Preferences unavailable: keep the default (sound on).
    }
  }

  static Future<void> setMuted(bool value) async {
    muted.value = value;
    if (!value) play(AibsSfx.pop);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {}
  }

  /// Sees every sound the app asks for, even while [enabled] is false.
  @visibleForTesting
  static void Function(AibsSfx sfx)? debugOnPlay;

  static void play(AibsSfx sfx) {
    if (muted.value) return;
    debugOnPlay?.call(sfx);
    if (!enabled) return;
    final now = DateTime.now();
    final last = _last[sfx];
    // Drop machine-gun repeats (double taps, nested handlers).
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 45)) {
      return;
    }
    _last[sfx] = now;
    unawaited(_play(sfx));
  }

  static Future<void> _play(AibsSfx sfx) async {
    try {
      await _configure();
      final voices = _players.putIfAbsent(
        sfx,
        () => List.generate(_voices, (_) => AudioPlayer()),
      );
      final i = _next[sfx] ?? 0;
      _next[sfx] = (i + 1) % voices.length;
      final player = voices[i];
      await player.stop();
      await player.play(
        AssetSource(sfx.asset),
        volume: sfx.volume,
        mode: PlayerMode.lowLatency,
      );
    } catch (error) {
      // Sound is decoration; never let it break a flow.
      debugPrint('AibsSound: $error');
    }
  }

  static Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    AudioLogger.logLevel = AudioLogLevel.none;
    if (kIsWeb) return;
    await AudioPlayer.global.setAudioContext(
      AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
        respectSilence: true,
      ).build(),
    );
  }
}
