import 'package:flutter/material.dart';

import '../theme/aibs_theme.dart';
import '../widgets/aibs_widgets.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _storyController = TextEditingController();
  final _foodController = TextEditingController();
  final _symptoms = <String>{};
  double _severity = 2;
  bool _showSummary = false;

  static const _symptomOptions = [
    'Sakit perut',
    'Kembung',
    'Diare',
    'Konstipasi',
    'Mual',
    'Lainnya',
  ];

  @override
  void dispose() {
    _storyController.dispose();
    _foodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSummary) return _buildSummary(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text('Jurnal', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        Text('Mau catat apa?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        AibsSecondaryButton(
          label: 'Ceritakan harimu',
          onPressed: () => _showStoryDialog(context),
        ),
        const SizedBox(height: 10),
        AibsSecondaryButton(
          label: 'Catat gejala',
          onPressed: () => _showSymptoms(context),
        ),
        const SizedBox(height: 24),
        Text('Catatan terakhir', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const AibsCard(child: Text('Belum ada catatan hari ini.')),
        const SizedBox(height: 24),
        AibsPrimaryButton(
          label: 'Lihat ringkasan',
          onPressed: () => setState(() => _showSummary = true),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Kembali',
              onPressed: () => setState(() => _showSummary = false),
              icon: const Icon(Icons.arrow_back),
            ),
            Text(
              'Ringkasan',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const AibsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hari ini', style: TextStyle(color: AibsColors.inkMuted)),
              SizedBox(height: 4),
              Text(
                'Belum ada pola yang cukup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Pola belum tentu penyebab.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        AibsSecondaryButton(
          label: 'Ringkasan buat konsultasi',
          onPressed: () => _showConsultationDialog(context),
        ),
        const SizedBox(height: 10),
        AibsSecondaryButton(
          label: 'Catatan asli',
          onPressed: () => _showOriginalNotes(context),
        ),
      ],
    );
  }

  void _showStoryDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tulis cerita', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _storyController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Apa yang kamu rasakan hari ini?',
              ),
            ),
            const SizedBox(height: 16),
            AibsPrimaryButton(
              label: 'Lanjut',
              onPressed: () {
                Navigator.pop(context);
                _showSummaryCheck(this.context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSymptoms(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, updateSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apa yang kamu rasain?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _symptomOptions)
                    AibsChoiceChip(
                      label: item,
                      selected: _symptoms.contains(item),
                      onTap: () => updateSheet(() {
                        if (!_symptoms.add(item)) _symptoms.remove(item);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Seberapa ganggu? ${_severity.round()}/5'),
              Slider(
                value: _severity,
                min: 1,
                max: 5,
                divisions: 4,
                label: '${_severity.round()}',
                onChanged: (value) => updateSheet(() => _severity = value),
              ),
              TextField(
                controller: _foodController,
                decoration: const InputDecoration(
                  labelText: 'Makanan sebelumnya',
                ),
              ),
              const SizedBox(height: 18),
              AibsPrimaryButton(
                label: 'Simpan catatan',
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Catatan tersimpan untuk sesi ini'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSummaryCheck(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cek hasil rapikan'),
        content: Text(
          _storyController.text.trim().isEmpty
              ? 'Belum ada cerita untuk dirapikan.'
              : _storyController.text.trim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ubah'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Catatan tersimpan untuk sesi ini'),
                ),
              );
              _storyController.clear();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showConsultationDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ringkasan buat konsultasi'),
        content: const Text('Belum ada cukup catatan untuk dibuat ringkasan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showOriginalNotes(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Catatan asli'),
        content: Text(
          _storyController.text.trim().isEmpty
              ? 'Belum ada catatan.'
              : _storyController.text.trim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
