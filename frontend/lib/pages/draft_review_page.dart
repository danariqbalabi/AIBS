import 'package:flutter/material.dart';

import '../core/demo_data.dart';
import '../core/theme/aibs_tokens.dart';
import '../data/app_services.dart';
import '../data/draft_review.dart';
import '../widgets/aibs_widgets.dart';
import '../widgets/record_card_form.dart';

class DraftReviewPage extends StatefulWidget {
  const DraftReviewPage({
    super.key,
    required this.review,
    this.meals = const [],
    this.ingredientId,
  });
  final DraftReview review;
  final List<AibsMealLog> meals;
  final String? Function(String)? ingredientId;
  @override
  State<DraftReviewPage> createState() => _DraftReviewPageState();
}

class _DraftReviewPageState extends State<DraftReviewPage> {
  bool _busy = false;
  String? _error;
  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.review.save();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = AppServices.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.review.content;
    final foods = (content['foods'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final symptoms = (content['symptoms'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    return Scaffold(
      appBar: AppBar(title: const Text('Cek sebelum simpan')),
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
                      child: Text(question.toString(), style: AibsType.caption),
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
                          onPressed: () => setState(() => symptoms.removeAt(i)),
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
                        initialValue: symptoms[i]['linked_food_index'] as int?,
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
              child: AibsPrimaryButton(
                label: _busy ? 'Menyimpan...' : 'Simpan semua',
                onPressed: _busy || (foods.isEmpty && symptoms.isEmpty)
                    ? null
                    : _save,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
