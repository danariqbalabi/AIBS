import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'aibs_sound.dart';

/// Plays [AibsSfx.tap] whenever the user taps something tappable (a button,
/// card, chip, row, tab...). Wrap once around the app (MaterialApp.builder).
///
/// A tap counts when the pointer goes down on a widget that has an enabled
/// tap handler and comes up without dragging. Disabled buttons and scrolls
/// stay silent. Use [AibsSoundTag] to swap or silence the sound for a subtree.
class AibsTapSounds extends StatefulWidget {
  const AibsTapSounds({super.key, required this.child, this.messengerKey});

  final Widget child;

  /// Key for the app's [ScaffoldMessenger]. Pass the one you would have given
  /// to MaterialApp.scaffoldMessengerKey; this widget hosts the messenger.
  final GlobalKey<ScaffoldMessengerState>? messengerKey;

  @override
  State<AibsTapSounds> createState() => _AibsTapSoundsState();
}

class _AibsTapSoundsState extends State<AibsTapSounds> {
  int? _pointer;
  Offset _down = Offset.zero;
  AibsSfx? _pending;

  void _onDown(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton &&
        event.kind == PointerDeviceKind.mouse) {
      return;
    }
    _pointer = event.pointer;
    _down = event.position;
    _pending = _soundAt(event);
  }

  void _onUp(PointerUpEvent event) {
    final sfx = _pending;
    if (event.pointer != _pointer || sfx == null) return;
    _pointer = null;
    _pending = null;
    if ((event.position - _down).distance > kTouchSlop) return;
    AibsSound.play(sfx);
  }

  void _onCancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) _pending = null;
  }

  AibsSfx? _soundAt(PointerEvent event) {
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(result, event.position, event.viewId);
    var tappable = false;
    for (final entry in result.path) {
      final target = entry.target;
      // GestureDetector exposes its tap on RenderSemanticsGestureHandler;
      // InkWell (and every Material button built on it) on a Semantics node.
      if ((target is RenderSemanticsGestureHandler && target.onTap != null) ||
          (target is SemanticsAnnotationsMixin &&
              target.properties.onTap != null)) {
        tappable = true;
      } else if (target is RenderMetaData && target.metaData is AibsSoundTag) {
        // The nearest tag decides, even if the tappable sits above it.
        return (target.metaData as AibsSoundTag).sfx;
      }
    }
    return tappable ? AibsSfx.tap : null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: AibsScaffoldMessenger(
        key: widget.messengerKey,
        child: widget.child,
      ),
    );
  }
}

/// Overrides the automatic tap sound for [child]: another sound, or none
/// (`sfx: null`) when the child plays its own.
class AibsSoundTag extends StatelessWidget {
  const AibsSoundTag({super.key, required this.sfx, required this.child});

  const AibsSoundTag.silent({super.key, required this.child}) : sfx = null;

  final AibsSfx? sfx;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MetaData(
      metaData: this,
      behavior: HitTestBehavior.deferToChild,
      child: child,
    );
  }
}

/// ScaffoldMessenger that chimes for confirmations ("... tersimpan") and plays
/// a soft notice for everything else (errors, "isi dulu" reminders).
class AibsScaffoldMessenger extends ScaffoldMessenger {
  const AibsScaffoldMessenger({super.key, required super.child});

  @override
  ScaffoldMessengerState createState() => _AibsScaffoldMessengerState();
}

class _AibsScaffoldMessengerState extends ScaffoldMessengerState {
  static final _success = RegExp(
    r'tersimpan|disimpan|ditambahkan|disalin|terkirim|berhasil',
    caseSensitive: false,
  );

  /// "Belum tersimpan", "Belum dikirim", "Tidak dapat ...": not a success,
  /// even when a success word appears in the same message.
  static final _notYet = RegExp(
    r'\bbelum\b|\btidak\b|\bgagal\b',
    caseSensitive: false,
  );

  @override
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    SnackBar snackBar, {
    AnimationStyle? snackBarAnimationStyle,
  }) {
    final content = snackBar.content;
    final text = content is Text ? content.data ?? '' : '';
    final ok = _success.hasMatch(text) && !_notYet.hasMatch(text);
    AibsSound.play(ok ? AibsSfx.success : AibsSfx.notice);
    return super.showSnackBar(
      snackBar,
      snackBarAnimationStyle: snackBarAnimationStyle,
    );
  }
}
