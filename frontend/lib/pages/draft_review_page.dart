import 'package:flutter/material.dart';

import '../core/demo_data.dart';
import '../core/theme/aibs_tokens.dart';
import '../data/app_services.dart';
import '../data/draft_review.dart';
import '../widgets/aibs_widgets.dart';
import '../widgets/record_card_form.dart';
import '../data/records_repository.dart';
import '../shared/widgets/status_badge.dart';
import '../widgets/unsaved_guard.dart';

class DraftReviewPage extends StatefulWidget {
  const DraftReviewPage({
    super.key,
    required this.review,
    this.meals = const [],
    this.ingredientId,
    this.onCheckFood,
  });
  final DraftReview review;
  final List<AibsMealLog> meals;
  final String? Function(String)? ingredientId;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)?
  onCheckFood;
  @override
  State<DraftReviewPage> createState() => _DraftReviewPageState();
}

class _DraftReviewPageState extends State<DraftReviewPage> {
  final _exit = GlobalKey<UnsavedGuardState>();
  bool _busy = false;
  String? _error;
  Future<void> _draftAction({bool discard = false}) async {
    if (_busy || widget.review.commitPending) return;
    if (discard) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Hapus draft ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (discard) {
        await widget.review.discard();
      } else {
        await widget.review.saveDraft();
      }
      if (mounted) await _exit.currentState!.leave(false);
    } catch (error) {
      if (mounted) setState(() => _error = AppServices.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check(int index, Map<String, dynamic> card) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.onCheckFood!(card);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: StatusBadge(statusFor(result['status'])),
          content: Text(
            [
              for (final reason in result['reasons'] as List? ?? [])
                reason['message'].toString(),
              ...((result['missing_information'] as List? ?? []).map(
                (v) => v.toString(),
              )),
            ].join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Kembali'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = AppServices.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.review.save();
      if (mounted) await _exit.currentState!.leave(true);
    } catch (error) {
      if (mounted) setState(() => _error = AppServices.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.review.content;
    final foods = (content.putIfAbsent('foods', () => []) as List)
        .cast<Map<String, dynamic>>();
    final symptoms = (content.putIfAbsent('symptoms', () => []) as List)
        .cast<Map<String, dynamic>>();
    return UnsavedGuard(
      key: _exit,
      isDirty: () => true,
      busy: () => _busy || widget.review.commitPending,
      onSaveDraft: widget.review.saveDraft,
      onDiscard: widget.review.discard,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cek sebelum simpan'),
          actions: [
            IconButton(
              tooltip: 'Hapus draft',
              onPressed: _busy || widget.review.commitPending
                  ? null
                  : () => _draftAction(discard: true),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: AbsorbPointer(
                absorbing: _busy || widget.review.commitPending,
                child: ListView(
                  padding: const EdgeInsets.all(AibsSpace.s20),
                  children: [
                    if (content['story'] != null)
                      AibsCard(child: Text(content['story'].toString())),
                    for (final question in content['questions'] as List? ?? [])
                      Padding(
                        padding: const EdgeInsets.only(top: AibsSpace.s12),
                        child: Text(
                          question.toString(),
                          style: AibsType.caption,
                        ),
                      ),
                    for (var i = 0; i < foods.length; i++) ...[
                      const SizedBox(height: AibsSpace.s20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Makanan ${i + 1}',
                              style: AibsType.sectionTitle,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Hapus kartu makanan',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              foods.removeAt(i);
                              for (final symptom in symptoms) {
                                final linked =
                                    symptom['linked_food_index'] as int?;
                                if (linked == i) {
                                  symptom['linked_food_index'] = null;
                                }
                                if (linked != null && linked > i) {
                                  symptom['linked_food_index'] = linked - 1;
                                }
                              }
                            }),
                          ),
                        ],
                      ),
                      RecordCardForm(
                        key: ObjectKey(foods[i]),
                        kind: 'food',
                        value: foods[i],
                        ingredientId: widget.ingredientId,
                      ),
                      if (widget.onCheckFood != null) ...[
                        TextButton(
                          onPressed: () => _check(i, foods[i]),
                          child: const Text('Cek sebelum makan'),
                        ),
                      ],
                    ],
                    for (var i = 0; i < symptoms.length; i++) ...[
                      const SizedBox(height: AibsSpace.s20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Gejala ${i + 1}',
                              style: AibsType.sectionTitle,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Hapus kartu gejala',
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(() => symptoms.removeAt(i)),
                          ),
                        ],
                      ),
                      RecordCardForm(
                        key: ObjectKey(symptoms[i]),
                        kind: 'symptom',
                        value: symptoms[i],
                        meals: widget.meals,
                      ),
                      if (foods.isNotEmpty)
                        DropdownButtonFormField<int>(
                          initialValue:
                              symptoms[i]['linked_food_index'] as int?,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Makanan dalam cerita',
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Tidak dihubungkan'),
                            ),
                            for (var n = 0; n < foods.length; n++)
                              DropdownMenuItem(
                                value: n,
                                child: Text(foods[n]['name'].toString()),
                              ),
                          ],
                          onChanged: (v) {
                            symptoms[i]['linked_food_index'] = v;
                            if (v != null) {
                              symptoms[i]['linked_food_event_id'] = null;
                            }
                          },
                        ),
                    ],
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: () => setState(
                            () => foods.add({
                              'name': '',
                              'consumed': false,
                              'ingredients': <dynamic>[],
                              'ingredients_complete': false,
                            }),
                          ),
                          child: const Text('Tambah makanan'),
                        ),
                        TextButton(
                          onPressed: () => setState(
                            () => symptoms.add({
                              'code': 'pain',
                              'present': true,
                              'severity': null,
                            }),
                          ),
                          child: const Text('Tambah gejala'),
                        ),
                      ],
                    ),
                    if (foods.isEmpty && symptoms.isEmpty)
                      const Text(
                        'Belum ada makanan atau gejala. Kembali dan isi manual.',
                      ),
                  ],
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
            if (widget.review.commitPending && !_busy)
              Padding(
                padding: const EdgeInsets.all(AibsSpace.s12),
                child: Text(
                  'Status simpan belum diterima. Coba simpan lagi untuk memeriksa.',
                  style: AibsType.caption,
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: AibsSpace.bottomActions,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _busy || widget.review.commitPending
                          ? null
                          : _draftAction,
                      child: const Text('Simpan draft'),
                    ),
                    AibsPrimaryButton(
                      label: _busy ? 'Menyimpan...' : 'Simpan semua',
                      onPressed: _busy || (foods.isEmpty && symptoms.isEmpty)
                          ? null
                          : _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
