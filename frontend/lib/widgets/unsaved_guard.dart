import 'package:flutter/material.dart';

import '../core/theme/aibs_tokens.dart';
import '../data/app_services.dart';

/// Blocks system and app-bar back until the user decides what to do with edits.
class UnsavedGuard extends StatefulWidget {
  const UnsavedGuard({
    super.key,
    required this.child,
    required this.isDirty,
    this.onSaveDraft,
    this.onDiscard,
    this.busy,
  });
  final Widget child;
  final bool Function() isDirty;
  final bool Function()? busy;
  final Future<void> Function()? onSaveDraft;
  final Future<void> Function()? onDiscard;
  @override
  State<UnsavedGuard> createState() => UnsavedGuardState();
}

class UnsavedGuardState extends State<UnsavedGuard> {
  bool _allow = false;
  bool _asking = false;
  Future<void> leave([Object? result]) async {
    if (!mounted) return;
    setState(() => _allow = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, result);
  }

  Future<void> _ask() async {
    if (_asking || widget.busy?.call() == true) return;
    if (!widget.isDirty()) {
      await leave();
      return;
    }
    _asking = true;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AibsSpace.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Perubahan belum disimpan',
                style: context.aibsText(AibsType.sheetTitle),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Lanjut isi'),
              ),
              if (widget.onSaveDraft != null)
                TextButton(
                  onPressed: () => Navigator.pop(c, 'save'),
                  child: const Text('Simpan draft'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(c, 'discard'),
                child: const Text('Buang perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action != null && mounted) {
      try {
        if (action == 'save') {
          await widget.onSaveDraft!();
        } else {
          await widget.onDiscard?.call();
        }
        await leave();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppServices.message(error))));
        }
      }
    }
    _asking = false;
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _allow,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _ask();
    },
    child: widget.child,
  );
}
