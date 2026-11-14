import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/demo_data.dart';
import '../core/theme/aibs_tokens.dart';
import '../data/app_services.dart';
import '../widgets/aibs_widgets.dart';
import '../widgets/record_card_form.dart';
import '../widgets/unsaved_guard.dart';

class EventEditorPage extends StatefulWidget {
  const EventEditorPage({
    super.key,
    required this.event,
    required this.onSave,
    this.ingredientId,
    this.meals = const [],
  });
  final Map<String, dynamic> event;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final String? Function(String)? ingredientId;
  final List<AibsMealLog> meals;
  @override
  State<EventEditorPage> createState() => _EventEditorPageState();
}

class _EventEditorPageState extends State<EventEditorPage> {
  final _exit = GlobalKey<UnsavedGuardState>();
  late final Map<String, dynamic> _event =
      jsonDecode(jsonEncode(widget.event)) as Map<String, dynamic>;
  bool _busy = false;
  String? _error;
  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSave(_event);
      if (mounted) await _exit.currentState!.leave(true);
    } catch (error) {
      if (mounted) setState(() => _error = AppServices.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => UnsavedGuard(
    key: _exit,
    isDirty: () => jsonEncode(_event) != jsonEncode(widget.event),
    busy: () => _busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Edit catatan')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AibsSpace.s20),
              child: RecordCardForm(
                kind: _event['kind'] as String,
                value: _event['payload'] as Map<String, dynamic>,
                ingredientId: widget.ingredientId,
                meals: widget.meals,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(AibsSpace.s16),
              child: Text(
                _error!,
                style: AibsType.caption.copyWith(color: AibsColors.badInk),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: AibsSpace.bottomActions,
              child: AibsPrimaryButton(
                label: _busy ? 'Menyimpan...' : 'Simpan perubahan',
                onPressed: _busy ? null : _save,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
