// Koala mascot.
//
//   Koala(KoalaMood.senang, size: 120)
//   KoalaBubble(mood: KoalaMood.senang, text: 'Ada keluhan setelah makan pagi tadi?')
//
// Needs flutter_svg and assets/brand/koala_{senang,mikir,khawatir}.svg.
// Rule: max one koala per screen, never recolored, never extra shadows.
//
// The koala is alive: it breathes, blinks, wiggles its ears and does a small
// mood gesture now and then (senang waves, mikir tilts its head and bubbles
// float, khawatir fidgets with a sweat drop). Tap it and it hops with a
// "boing". With reduced motion (or `animate: false`) it renders the static
// brand SVG exactly as before.
//
// Day and night follow the theme. Light: a small sun turns beside large
// koalas. Dark: a crescent moon with twinkling stars, a darker ground shadow,
// and a sleepier koala (slower breath, longer blinks, eyes resting lower, and
// a yawn instead of its mood gesture). Colors of the koala never change.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/sound/aibs_sound.dart';
import '../../core/sound/aibs_tap_sounds.dart';
import '../../core/theme/aibs_tokens.dart';
import 'koala_parts.dart';

enum KoalaMood { senang, mikir, khawatir }

class Koala extends StatefulWidget {
  const Koala(
    this.mood, {
    super.key,
    this.size = 120,
    this.semanticLabel,
    this.animate = true,
    this.interactive = true,
    this.entrySound,
    this.sky,
  });

  final KoalaMood mood;

  /// Sun (light theme) or moon (dark theme) above the left ear.
  /// Null = automatic: shown for large koalas ([skyMinSize] and up), hidden
  /// in bubbles, verdict cards, and small empty states.
  final bool? sky;

  static const skyMinSize = 150.0;

  /// Sizes used in the design: bubble 84–96, verdict 140–150,
  /// hero/empty 170–200, welcome 230.
  final double size;

  /// Null = decorative (when nearby text already says what matters).
  final String? semanticLabel;

  /// False renders the static SVG.
  final bool animate;

  /// Tap to make the koala hop.
  final bool interactive;

  /// Played once when the koala first appears (e.g. success on "Tersimpan").
  final AibsSfx? entrySound;

  /// App-wide switch. Tests turn it off (test/flutter_test_config.dart) so
  /// `pumpAndSettle` doesn't wait on the endless idle loop.
  static bool animationsEnabled = true;

  @override
  State<Koala> createState() => _KoalaState();
}

class _KoalaState extends State<Koala> with TickerProviderStateMixin {
  static const _tau = 2 * math.pi;
  static const _deg = math.pi / 180;

  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  );
  late final _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
  );
  late final _gesture = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final _poke = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  late final _enter = AnimationController(
    vsync: this,
    duration: AibsMotion.verdict,
  );

  /// Slow clock for the sky (sun rays, moon sway, stars). Every sky period
  /// divides 24 s so the loop is seamless.
  late final _skyClock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  late final Listenable _frame = Listenable.merge([
    _idle,
    _blink,
    _gesture,
    _poke,
    _enter,
    _skyClock,
  ]);

  final _random = math.Random();
  Timer? _blinkTimer;
  Timer? _blinkHoldTimer;
  Timer? _gestureTimer;
  bool _running = false;
  bool _fadeIn = true;

  /// Dark theme: sleepier koala and a moon.
  bool _night = false;

  /// How far the current blink closes the eyes (night "lingers" stop halfway).
  double _blinkDepth = 1;

  bool get _showSky => widget.sky ?? widget.size >= Koala.skyMinSize;

  _Layers? _layers;

  bool get _animated =>
      widget.animate &&
      Koala.animationsEnabled &&
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void initState() {
    super.initState();
    final sfx = widget.entrySound;
    if (sfx != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AibsSound.play(sfx);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final night = Theme.of(context).brightness == Brightness.dark;
    if (night != _night) {
      _night = night;
      _idle.duration = Duration(milliseconds: night ? 5000 : 4000);
      _gesture.duration = Duration(milliseconds: night ? 2600 : 1600);
      if (_running) {
        _idle.repeat();
        _scheduleGesture(first: true);
      }
    }
    _sync();
  }

  @override
  void didUpdateWidget(covariant Koala oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood && _running) {
      _fadeIn = false;
      _enter.forward(from: 0);
    }
    _sync();
  }

  @override
  void dispose() {
    _running = false; // stops callbacks that fire while controllers dispose
    _cancelTimers();
    _idle.dispose();
    _blink.dispose();
    _gesture.dispose();
    _poke.dispose();
    _enter.dispose();
    _skyClock.dispose();
    super.dispose();
  }

  void _cancelTimers() {
    _blinkTimer?.cancel();
    _blinkHoldTimer?.cancel();
    _gestureTimer?.cancel();
  }

  void _sync() {
    final animated = _animated;
    if (animated == _running) return;
    _running = animated;
    if (animated) {
      _idle.repeat();
      _skyClock.repeat();
      _enter.forward(from: 0);
      _scheduleBlink();
      _scheduleGesture(first: true);
    } else {
      _cancelTimers();
      _idle.stop();
      _skyClock.stop();
      _blink.value = 0;
      _enter.value = 1;
    }
  }

  void _scheduleBlink({int extraWait = 0}) {
    _blinkTimer?.cancel();
    final wait = (_night ? 3000 : 2200) + _random.nextInt(3000) + extraWait;
    _blinkTimer = Timer(Duration(milliseconds: wait), () {
      if (!mounted || !_running) return;
      final linger = _night && _random.nextDouble() < 0.35;
      _blink.duration = Duration(milliseconds: _night ? 320 : 170);
      _blinkDepth = linger ? 0.55 : 1;
      if (linger) {
        // Eyes drift half shut, rest there, then open again.
        _blink.value = 0;
        _blink.animateTo(0.5).whenCompleteOrCancel(() {
          // Also fires when the koala is disposed mid-blink: no new timer then.
          if (!mounted || !_running) return;
          _blinkHoldTimer?.cancel();
          _blinkHoldTimer = Timer(const Duration(milliseconds: 1300), () {
            if (mounted && _running) _blink.animateTo(1);
          });
        });
      } else {
        _blink.forward(from: 0).whenCompleteOrCancel(() {
          // Sometimes a quick double blink (daytime only).
          if (mounted && _running && !_night && _random.nextDouble() < 0.25) {
            _blink.forward(from: 0);
          }
        });
      }
      _scheduleBlink(extraWait: linger ? 1300 : 0);
    });
  }

  void _scheduleGesture({bool first = false}) {
    _gestureTimer?.cancel();
    final wait = switch ((first, _night)) {
      (true, false) => 900 + _random.nextInt(900),
      (true, true) => 2200 + _random.nextInt(900),
      (false, false) => 5000 + _random.nextInt(4500),
      (false, true) => 7000 + _random.nextInt(4500),
    };
    _gestureTimer = Timer(Duration(milliseconds: wait), () {
      if (!mounted || !_running) return;
      _gesture.forward(from: 0);
      _scheduleGesture();
    });
  }

  void _onTap() {
    AibsSound.play(AibsSfx.koala);
    HapticFeedback.lightImpact();
    if (!_running) return;
    _poke.forward(from: 0);
    _blinkHoldTimer?.cancel();
    _blinkDepth = 1;
    _blink.duration = const Duration(milliseconds: 170);
    _blink.forward(from: 0);
    if (!_gesture.isAnimating) _gesture.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_animated) {
      final parts = switch (widget.mood) {
        KoalaMood.senang => KoalaParts.senang,
        KoalaMood.mikir => KoalaParts.mikir,
        KoalaMood.khawatir => KoalaParts.khawatir,
      };
      final layers = _layers?.matches(parts, widget.size) == true
          ? _layers!
          : _layers = _Layers(parts, widget.size);
      child = SizedBox.square(
        dimension: widget.size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _frame,
            builder: (context, _) => _paint(layers),
          ),
        ),
      );
    } else {
      child = SvgPicture.asset(
        'assets/brand/koala_${widget.mood.name}.svg',
        width: widget.size,
        height: widget.size,
        excludeFromSemantics: true,
      );
      if (_showSky) {
        child = SizedBox.square(
          dimension: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: child),
              _skyLayer(),
            ],
          ),
        );
      }
    }

    if (widget.interactive) {
      child = AibsSoundTag.silent(
        child: GestureDetector(
          onTap: _onTap,
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          child: child,
        ),
      );
    }

    final label = widget.semanticLabel;
    return label == null
        ? ExcludeSemantics(child: child)
        : Semantics(image: true, label: label, child: child);
  }

  Widget _paint(_Layers l) {
    final p = l.parts;
    final s = widget.size / koalaCanvas;

    final t = _idle.value;
    final breath = 0.5 - 0.5 * math.cos(_tau * t);
    final night = _night;
    final g = _gesture.value;
    final inGesture = g > 0 && g < 1;
    // By day the gesture is the mood move; by night it is a yawn instead.
    final gEnv = inGesture && !night ? math.sin(math.pi * g) : 0.0;
    final yawn = inGesture && night
        ? _smooth(g / 0.3) * (1 - _smooth((g - 0.62) / 0.3))
        : 0.0;
    final closed = (1 - (2 * _blink.value - 1).abs()) * _blinkDepth;
    final enter = AibsMotion.emphasized.transform(_enter.value);

    // Poke: squash, hop, land.
    final poke = _poke.value;
    var hop = 0.0, sx = 1.0, sy = 1.0, flick = 0.0;
    if (poke > 0 && poke < 1) {
      if (poke < 0.15) {
        final k = math.sin(poke / 0.15 * math.pi / 2);
        sy = 1 - 0.08 * k;
        sx = 1 + 0.06 * k;
      } else if (poke < 0.7) {
        final q = (poke - 0.15) / 0.55;
        final k = math.sin(math.pi * q);
        final rest = math.pow(1 - q, 4).toDouble();
        hop = -18 * k;
        sy = 1 + 0.05 * k - 0.08 * rest;
        sx = 1 - 0.03 * k + 0.06 * rest;
        flick = k;
      } else {
        final r = (poke - 0.7) / 0.3;
        final k = math.sin(math.pi * r) * (1 - 0.4 * r);
        sy = 1 - 0.07 * k;
        sx = 1 + 0.05 * k;
      }
    }

    // Mood motion.
    var dx = 0.0;
    var headTilt = 0.0;
    var eyesDx = 0.0, eyesDy = 0.0;
    var armAngle = 0.0, armRightAngle = 0.0;
    var waveAngle = 0.0, leafAngle = 0.0;
    var earExtra = 0.0;
    switch (widget.mood) {
      case KoalaMood.senang:
        headTilt = 1.5 * math.sin(_tau * t);
        waveAngle =
            gEnv * (-8 + 16 * math.sin(_tau * 2.5 * g)) -
            14 * yawn - // stretches the arm while yawning
            10 * flick;
        leafAngle = (night ? 3 : 5) * math.sin(_tau * 2 * t);
      case KoalaMood.mikir:
        headTilt = 2.5 + 1.5 * math.sin(_tau * t) + 4 * gEnv;
        eyesDx = 1.5 * math.sin(_tau * t) + 1.5 * gEnv;
        eyesDy = -1.5 * gEnv;
        armAngle = 2 * math.sin(_tau * 4 * t);
      case KoalaMood.khawatir:
        dx = 1.2 * math.sin(_tau * t) + 1.4 * gEnv * math.sin(_tau * 10 * g);
        headTilt = -1.2 * math.sin(_tau * t);
        armAngle = (night ? 2.5 : 4) * math.sin(_tau * 3 * t);
        armRightAngle = -armAngle;
        earExtra = 4 * gEnv * math.sin(_tau * 8 * g);
    }
    headTilt -= 5 * yawn; // head tips back on a yawn
    final wiggle =
        (night ? 0.0 : 9 * math.sin(_tau * 2 * g) * (1 - g)) + earExtra;
    final ear = wiggle + 12 * flick + 7 * yawn;

    // Night eyes rest a little lower and squint through a yawn.
    final eyeScale = math.max(
      0.08,
      1 - (night ? 0.12 : 0) - 0.9 * closed - 0.7 * yawn,
    );

    final grow = 0.88 + 0.12 * enter;
    final body = _around(
      KoalaParts.feet,
      s,
      dx: dx,
      dy: -2.5 * breath + hop,
      sx: grow * sx * (1 - 0.006 * breath),
      sy: grow * sy * (1 + 0.025 * yawn) * (1 + 0.012 * breath),
    );
    final shadow = _around(
      KoalaParts.feet,
      s,
      dx: dx,
      sx: grow * (1 - 0.05 * breath + hop / 18 * 0.3),
      sy: grow,
    );
    final head = _around(KoalaParts.neck, s, angle: headTilt * _deg);

    final headLayers = <Widget>[
      l.layer(
        l.earLeft,
        _around(KoalaParts.earLeftPivot, s, angle: -ear * _deg),
      ),
      l.layer(
        l.earRight,
        _around(KoalaParts.earRightPivot, s, angle: ear * _deg),
      ),
      l.layer(l.head),
      l.layer(
        l.eyes,
        _around((x: 120.0, y: p.eyeY), s, dx: eyesDx, dy: eyesDy, sy: eyeScale),
      ),
      // Always mounted (hidden at rest) so its picture is loaded before the
      // first yawn instead of popping in mid-gesture.
      l.layer(
        l.yawn,
        _around(
          KoalaParts.yawnCenter,
          s,
          sx: math.max(yawn, 0.01),
          sy: math.max(yawn, 0.01),
        ),
        yawn > 0 ? 1 : 0,
      ),
      for (var i = 0; i < l.bubbles.length; i++) _bubble(l, i, t, gEnv, s),
      if (l.drop != null) _drop(l, t, s),
    ];

    final bodyLayers = <Widget>[
      l.layer(l.body),
      if (l.wavingArm != null)
        l.layer(
          l.wavingArm!,
          _around(p.wavingArmPivot!, s, angle: waveAngle * _deg),
        ),
      Positioned.fill(
        child: Transform(
          transform: head,
          child: Stack(clipBehavior: Clip.none, children: headLayers),
        ),
      ),
      l.layer(l.scarf),
      if (l.arm != null)
        l.layer(l.arm!, _around(p.armPivot!, s, angle: armAngle * _deg)),
      if (l.armRight != null)
        l.layer(
          l.armRight!,
          _around(p.armRightPivot!, s, angle: armRightAngle * _deg),
        ),
      if (l.leaf != null)
        l.layer(
          l.leaf!,
          _around(KoalaParts.leafPivot, s, angle: leafAngle * _deg),
        ),
    ];

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        l.layer(night ? l.shadowNight : l.shadow, shadow),
        Positioned.fill(
          child: Transform(
            transform: body,
            child: Stack(clipBehavior: Clip.none, children: bodyLayers),
          ),
        ),
        if (_showSky) _skyLayer(t: t, poke: poke),
      ],
    );
    return _fadeIn && enter < 1 ? Opacity(opacity: enter, child: stack) : stack;
  }

  static double _smooth(double x) {
    final c = x.clamp(0.0, 1.0);
    return c * c * (3 - 2 * c);
  }

  /// Sun or moon above the left ear. Static when [t] is null.
  Widget _skyLayer({double? t, double poke = 0}) {
    final sky = _skyPictures(widget.size);
    final k = sky.px / KoalaSky.canvas;
    final s = widget.size / koalaCanvas;
    final moving = t != null;
    final elapsed = _skyClock.value * 24000; // ms within the 24 s loop
    final popping = poke > 0 && poke < 1;
    final bounce = popping
        ? -6 * math.sin(math.pi * math.min(1, poke * 1.2))
        : 0.0;

    final List<Widget> children;
    if (!_night) {
      final spin = moving
          ? _skyClock.value * _tau +
                (popping ? 0.5 * math.sin(math.pi * poke) : 0)
          : 0.0;
      final pulse = moving ? 1 + 0.04 * math.sin(_tau * t) : 1.0;
      children = [
        _skyPart(
          sky.sunRays,
          _around(KoalaSky.center, k, angle: spin, dy: bounce),
        ),
        _skyPart(
          sky.sunCore,
          _around(KoalaSky.center, k, sx: pulse, sy: pulse, dy: bounce),
        ),
      ];
    } else {
      final sway = moving ? 6 * math.sin(_tau * elapsed / 6000) : 0.0;
      final bob = moving ? 1.5 * math.sin(_tau * t) : 0.0;
      children = [
        _skyPart(
          sky.moon,
          _around(KoalaSky.moonCenter, k, angle: sway * _deg, dy: bounce + bob),
        ),
        for (var i = 0; i < sky.stars.length; i++)
          _skyPart(
            sky.stars[i],
            null,
            moving
                ? 0.35 +
                      0.65 *
                          (0.5 +
                              0.5 *
                                  math.sin(
                                    _tau * elapsed / (2000 + i * 1000) + i * 2,
                                  ))
                : 1,
          ),
      ];
    }
    return Positioned(
      key: ValueKey(_night ? 'koala-moon' : 'koala-sun'),
      left: KoalaSky.left * s,
      top: KoalaSky.top * s,
      width: sky.px,
      height: sky.px,
      child: IgnorePointer(
        child: Stack(clipBehavior: Clip.none, children: children),
      ),
    );
  }

  Widget _skyPart(Widget picture, Matrix4? transform, [double opacity = 1]) {
    var child = picture;
    if (transform != null) {
      child = Transform(transform: transform, child: child);
    }
    if (opacity < 1) child = Opacity(opacity: opacity, child: child);
    return Positioned.fill(child: child);
  }

  _SkyPictures? _sky;
  _SkyPictures _skyPictures(double koalaSize) {
    final px = KoalaSky.size * koalaSize / koalaCanvas;
    final cached = _sky;
    if (cached != null && cached.px == px) return cached;
    return _sky = _SkyPictures(px);
  }

  Widget _bubble(_Layers l, int i, double t, double gEnv, double s) {
    final center = l.parts.bubbles[i].$2;
    final phase = _tau * 2 * t - i * 0.9;
    final scale = 1 + 0.14 * math.sin(phase) + 0.15 * gEnv;
    return l.layer(
      l.bubbles[i],
      _around(
        center,
        s,
        dy: -2.5 * math.sin(_tau * t - i * 0.9),
        sx: scale,
        sy: scale,
      ),
    );
  }

  Widget _drop(_Layers l, double t, double s) {
    final d = (t * 2) % 1;
    final opacity = d < 0.12
        ? d / 0.12
        : d > 0.7
        ? (1 - d) / 0.3
        : 1.0;
    final scale = 0.7 + 0.3 * math.min(1, d / 0.12);
    return l.layer(
      l.drop!,
      _around((x: 190.0, y: 49.0), s, dy: 20 * d * d, sx: scale, sy: scale),
      opacity,
    );
  }

  /// Rotate/scale around [pivot] then translate; all in koala canvas units.
  static Matrix4 _around(
    KoalaPoint pivot,
    double s, {
    double angle = 0,
    double sx = 1,
    double sy = 1,
    double dx = 0,
    double dy = 0,
  }) {
    final px = pivot.x * s, py = pivot.y * s;
    return Matrix4.identity()
      ..translateByDouble(px + dx * s, py + dy * s, 0, 1)
      ..rotateZ(angle)
      ..scaleByDouble(sx, sy, 1, 1)
      ..translateByDouble(-px, -py, 0, 1);
  }
}

/// SvgPicture widgets built once per mood and size, reused every frame.
class _Layers {
  _Layers(this.parts, this.size)
    : shadow = _pic(parts.shadow, size),
      shadowNight = _pic(KoalaParts.shadowNight, size),
      yawn = _pic(parts.yawn, size),
      body = _pic(parts.body, size),
      earLeft = _pic(parts.earLeft, size),
      earRight = _pic(parts.earRight, size),
      head = _pic(parts.head, size),
      eyes = _pic(parts.eyes, size),
      scarf = _pic(parts.scarf, size),
      arm = _opt(parts.arm, size),
      armRight = _opt(parts.armRight, size),
      wavingArm = _opt(parts.wavingArm, size),
      leaf = _opt(parts.leaf, size),
      drop = _opt(parts.drop, size),
      bubbles = [for (final b in parts.bubbles) _pic(b.$1, size)];

  final KoalaParts parts;
  final double size;
  final Widget shadow, shadowNight, body, earLeft, earRight, head, eyes, scarf;
  final Widget yawn;
  final Widget? arm, armRight, wavingArm, leaf, drop;
  final List<Widget> bubbles;

  bool matches(KoalaParts other, double otherSize) =>
      identical(parts, other) && size == otherSize;

  Widget layer(Widget picture, [Matrix4? transform, double opacity = 1]) {
    var child = picture;
    if (transform != null) {
      child = Transform(transform: transform, child: child);
    }
    if (opacity < 1) {
      child = Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);
    }
    return Positioned.fill(child: child);
  }

  static Widget _pic(String svg, double size) => SvgPicture.string(
    svg,
    width: size,
    height: size,
    excludeFromSemantics: true,
  );

  static Widget? _opt(String? svg, double size) =>
      svg == null ? null : _pic(svg, size);
}

/// Koala asking something through a speech bubble (Hari Ini prompt, H1p).
///
/// Layout: koala + bubble aligned to the bottom. The bubble keeps a bottom
/// margin so its text never rises above the koala's ear tips. Keep [text]
/// to one short question; put the actions below this widget.
class KoalaBubble extends StatelessWidget {
  const KoalaBubble({
    super.key,
    required this.text,
    this.mood = KoalaMood.senang,
    this.koalaSize = 84,
  });

  final String text;
  final KoalaMood mood;
  final double koalaSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Koala(mood, size: koalaSize),
        const SizedBox(width: AibsSpace.s6),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: koalaSize >= 96 ? 16 : 14),
            padding: const EdgeInsets.symmetric(
              horizontal: AibsSpace.s14,
              vertical: AibsSpace.s12,
            ),
            decoration: BoxDecoration(
              color: context.aibsColor(AibsColors.card),
              borderRadius: AibsRadius.bubbleShape,
              boxShadow: AibsShadows.bubble,
            ),
            child: Text(
              text,
              style: context
                  .aibsText(AibsType.bodyStrong)
                  .copyWith(fontSize: koalaSize >= 96 ? 16 : 15),
            ),
          ),
        ),
      ],
    );
  }
}

/// Result hero: koala bottom-left, short headline bottom-aligned to its right.
/// Used on F6 (status soft background) and B6 (hero gradient).
class VerdictCard extends StatelessWidget {
  const VerdictCard({
    super.key,
    required this.mood,
    required this.headline,
    this.label,
    this.detail,
    this.headlineColor = AibsColors.ink,
    this.color,
    this.gradient,
    this.koalaSize = 140,
  });

  final KoalaMood mood;
  final String
  headline; // keep it short: one or two lines, never above the ears
  final String? label; // small line above the headline
  final String? detail; // one short reason line under the headline
  final Color headlineColor;
  final Color? color;
  final Gradient? gradient;
  final double koalaSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color == null ? null : context.aibsColor(color!),
        gradient: gradient == null ? null : context.aibsGradient(gradient!),
        borderRadius: BorderRadius.circular(AibsRadius.xxl),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 4,
            bottom: -8,
            child: Koala(
              mood,
              size: koalaSize,
              entrySound: switch (mood) {
                KoalaMood.senang => AibsSfx.success,
                KoalaMood.khawatir => AibsSfx.notice,
                KoalaMood.mikir => null,
              },
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: koalaSize),
            child: Align(
              alignment: Alignment.bottomLeft,
              heightFactor: 1,
              child: Padding(
                padding: EdgeInsets.fromLTRB(koalaSize + 4, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label != null)
                      Text(
                        label!,
                        style: context
                            .aibsText(AibsType.caption)
                            .copyWith(
                              color: context.aibsColor(
                                AibsColors.primaryStrong,
                              ),
                              fontWeight: AibsType.w800,
                            ),
                      ),
                    Text(
                      headline,
                      style: context
                          .aibsText(AibsType.verdict)
                          .copyWith(color: context.aibsColor(headlineColor)),
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: AibsSpace.s4),
                      Text(detail!, style: context.aibsText(AibsType.caption)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sun and moon pictures for one sky size, reused every frame.
class _SkyPictures {
  _SkyPictures(this.px)
    : sunRays = _pic(KoalaSky.sunRays, px),
      sunCore = _pic(KoalaSky.sunCore, px),
      moon = _pic(KoalaSky.moon, px),
      stars = [for (final s in KoalaSky.stars) _pic(s, px)];

  final double px;
  final Widget sunRays, sunCore, moon;
  final List<Widget> stars;

  static Widget _pic(String svg, double size) => SvgPicture.string(
    svg,
    width: size,
    height: size,
    excludeFromSemantics: true,
  );
}
