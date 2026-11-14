import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/demo_data.dart';
import '../core/theme/aibs_tokens.dart';
import '../shared/widgets/koala.dart';
import '../widgets/aibs_widgets.dart';
import 'profile_setup_flow.dart';
import '../data/consultation_pdf.dart';
import '../data/export_file.dart';
import '../data/app_services.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({
    required this.meals,
    required this.symptoms,
    required this.profile,
    required this.onOpenJournal,
    super.key,
    this.loadSummary,
  });

  final List<AibsMealLog> meals;
  final List<AibsSymptomLog> symptoms;
  final ProfileSetupAnswers? profile;
  final VoidCallback onOpenJournal;
  final Future<Map<String, dynamic>> Function(int)? loadSummary;

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  int _period = 7;
  Future<Map<String, dynamic>>? _summaryFuture;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _summaryFuture = widget.loadSummary?.call(_period);
  }

  void _changePeriod(int period) => setState(() {
    _period = period;
    _summaryFuture = widget.loadSummary?.call(period);
  });

  @override
  Widget build(BuildContext context) {
    if (_summaryFuture == null) return _render(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ringkasan')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ringkasan')),
            body: Center(
              child: AibsSecondaryButton(
                label: 'Coba lagi',
                onPressed: () => _changePeriod(_period),
              ),
            ),
          );
        }
        _report = snapshot.data;
        return _render(context);
      },
    );
  }

  Widget _render(BuildContext context) {
    final meals = _mealsInPeriod;
    final symptoms = _symptomsInPeriod;
    final activeDays = {
      ...meals.map((entry) => DateUtils.dateOnly(entry.date)),
      ...symptoms.map((entry) => DateUtils.dateOnly(entry.date)),
    };
    final enoughData = _report == null
        ? meals.length >= 3 && symptoms.isNotEmpty && activeDays.length >= 3
        : _report!['status'] != 'insufficient_data';

    return Scaffold(
      appBar: AppBar(title: const Text('Ringkasan')),
      body: enoughData
          ? _buildSummary(context, meals, symptoms)
          : _buildEmpty(
              context,
              _report?['logged_days'] as int? ?? activeDays.length,
            ),
    );
  }

  List<AibsMealLog> get _mealsInPeriod => widget.meals
      .where(
        (entry) =>
            !DateUtils.dateOnly(entry.date).isBefore(
              DateUtils.dateOnly(DateTime.now())
                  .subtract(Duration(days: _period - 1)),
            ) &&
            !DateUtils.dateOnly(entry.date)
                .isAfter(DateUtils.dateOnly(DateTime.now())),
      )
      .toList();

  List<AibsSymptomLog> get _symptomsInPeriod => widget.symptoms
      .where(
        (entry) =>
            !DateUtils.dateOnly(entry.date).isBefore(
              DateUtils.dateOnly(DateTime.now())
                  .subtract(Duration(days: _period - 1)),
            ) &&
            !DateUtils.dateOnly(entry.date)
                .isAfter(DateUtils.dateOnly(DateTime.now())),
      )
      .toList();

  Widget _buildEmpty(BuildContext context, int activeDays) {
    return ListView(
      padding: const EdgeInsets.all(AibsSpace.s20),
      children: [
        Row(
          children: [
            for (final period in [7, 30])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AibsSpace.s8),
                  child: AibsChoiceChip(
                    label: '$period hari',
                    selected: _period == period,
                    onTap: () => _changePeriod(period),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AibsSpace.s28),
        const Center(child: Koala(KoalaMood.mikir, size: 180)),
        const SizedBox(height: AibsSpace.s16),
        Text(
          'Catatannya belum cukup',
          textAlign: TextAlign.center,
          style: AibsType.title,
        ),
        const SizedBox(height: AibsSpace.s12),
        Row(
          children: [
            for (var index = 0; index < 7; index++)
              Expanded(
                child: Container(
                  height: AibsSpace.s8,
                  margin: const EdgeInsets.symmetric(horizontal: AibsSpace.s2),
                  decoration: BoxDecoration(
                    color: index < activeDays
                        ? AibsColors.primary
                        : AibsColors.line,
                    borderRadius: BorderRadius.circular(AibsRadius.pill),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AibsSpace.s8),
        Text('$activeDays dari 7 hari', textAlign: TextAlign.center),
        const SizedBox(height: AibsSpace.s24),
        AibsPrimaryButton(
          label: 'Catat hari ini',
          onPressed: widget.onOpenJournal,
        ),
        const SizedBox(height: AibsSpace.s10),
        AibsSecondaryButton(
          label: 'Lihat catatan yang ada',
          onPressed: () {
            Navigator.pop(context);
            widget.onOpenJournal();
          },
        ),
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context,
    List<AibsMealLog> meals,
    List<AibsSymptomLog> symptoms,
  ) {
    final uniqueDays = {
      ...meals.map((entry) => DateUtils.dateOnly(entry.date)),
      ...symptoms.map((entry) => DateUtils.dateOnly(entry.date)),
    };
    final unknownCount =
        _report?['unknown_composition_count'] as int? ??
        meals.where((meal) => meal.note != null).length;
    final frequent = _frequentSymptom(symptoms);
    final frequentCount = symptoms
        .where((symptom) => symptom.name == frequent)
        .length;
    final matchingMeals = symptoms
        .where(
          (symptom) =>
              symptom.name == frequent &&
              (symptom.mealId != null || symptom.mealName != null),
        )
        .length;
    return ListView(
      padding: const EdgeInsets.all(AibsSpace.s20),
      children: [
        Row(
          children: [
            for (final period in [7, 30])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AibsSpace.s8),
                  child: AibsChoiceChip(
                    label: '$period hari',
                    selected: _period == period,
                    onTap: () => _changePeriod(period),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AibsSpace.s16),
        AibsCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      value: '${meals.length}',
                      label: 'catatan makan',
                    ),
                  ),
                  Expanded(
                    child: _StatTile(
                      value: '${symptoms.length}',
                      label: 'gejala',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AibsSpace.s16),
              _SummaryDayStrip(
                activeDays: uniqueDays.map((day) => day.day).toSet(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AibsSpace.s16),
        Container(
          padding: const EdgeInsets.all(AibsSpace.s16),
          decoration: BoxDecoration(
            color: AibsColors.card,
            borderRadius: BorderRadius.circular(AibsRadius.xl),
            border: Border.all(color: AibsColors.primary, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$frequent ${frequentCount}x · $matchingMeals x setelah catatan makan',
                style: AibsType.bodyStrong,
              ),
              const SizedBox(height: AibsSpace.s4),
              Text('Belum tentu penyebab', style: AibsType.micro),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _openPattern(context, frequent),
                  child: const Text('Lihat catatan ›'),
                ),
              ),
            ],
          ),
        ),
        if (unknownCount > 0) ...[
          const SizedBox(height: AibsSpace.s12),
          AibsCard(
            child: Text(
              '? $unknownCount bahan belum diketahui',
              style: AibsType.bodyStrong,
            ),
          ),
        ],
        const SizedBox(height: AibsSpace.s20),
        AibsPrimaryButton(
          label: 'Ringkasan buat konsultasi',
          onPressed: () => _openConsultation(context, meals, symptoms),
        ),
      ],
    );
  }

  String _frequentSymptom(List<AibsSymptomLog> symptoms) {
    final counts = <String, int>{};
    for (final entry in symptoms) {
      for (final name in entry.name.split(', ')) {
        counts.update(name, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    if (counts.isEmpty) return 'Gejala';
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  void _openPattern(BuildContext context, String symptom) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PatternDetailPage(
          symptom: symptom,
          meals: _mealsInPeriod,
          symptoms: _symptomsInPeriod,
          onOpenJournal: widget.onOpenJournal,
        ),
      ),
    );
  }

  void _openConsultation(
    BuildContext context,
    List<AibsMealLog> meals,
    List<AibsSymptomLog> symptoms,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ConsultationSummaryPage(
          profile: widget.profile,
          meals: meals,
          symptoms: symptoms,
          days: _period,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AibsSpace.s4),
      padding: const EdgeInsets.all(AibsSpace.s12),
      decoration: BoxDecoration(
        color: AibsColors.primarySoft,
        borderRadius: BorderRadius.circular(AibsRadius.md),
      ),
      child: Column(
        children: [
          Text(value, style: AibsType.title),
          Text(label, style: AibsType.small, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SummaryDayStrip extends StatelessWidget {
  const _SummaryDayStrip({required this.activeDays});
  final Set<int> activeDays;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '7 hari terakhir',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var index = 6; index >= 0; index--)
            Container(
              width: AibsSpace.s20,
              height: AibsSpace.s20,
              decoration: BoxDecoration(
                color:
                    activeDays.contains(
                      DateTime.now().subtract(Duration(days: index)).day,
                    )
                    ? AibsColors.primary
                    : AibsColors.unknownSoft,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _PatternDetailPage extends StatelessWidget {
  const _PatternDetailPage({
    required this.symptom,
    required this.meals,
    required this.symptoms,
    required this.onOpenJournal,
  });
  final String symptom;
  final List<AibsMealLog> meals;
  final List<AibsSymptomLog> symptoms;
  final VoidCallback onOpenJournal;

  @override
  Widget build(BuildContext context) {
    final entries = symptoms.where((entry) => entry.name.contains(symptom));
    return Scaffold(
      appBar: AppBar(title: Text('$symptom · 7 hari')),
      body: ListView(
        padding: const EdgeInsets.all(AibsSpace.s20),
        children: [
          for (final entry in entries) ...[
            Text(
              '${entry.date.day} ${_month(entry.date.month)}',
              style: AibsType.caption,
            ),
            const SizedBox(height: AibsSpace.s8),
            AibsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.time} · $symptom · ${entry.severity ?? 'belum diisi'}',
                  ),
                  if (entry.mealName != null) ...[
                    const SizedBox(height: AibsSpace.s8),
                    Text('Sebelum ${entry.mealName}'),
                    const Text('Belum tentu penyebab'),
                  ],
                  if (entry.note != null) Text(entry.note!),
                ],
              ),
            ),
            const SizedBox(height: AibsSpace.s12),
          ],
          if (meals.isEmpty && symptoms.isEmpty)
            const AibsCard(child: Text('Belum ada catatan pada periode ini.')),
          AibsSecondaryButton(
            label: 'Lihat catatan',
            onPressed: () {
              Navigator.pop(context);
              onOpenJournal();
            },
          ),
        ],
      ),
    );
  }
}

class _ConsultationSummaryPage extends StatefulWidget {
  const _ConsultationSummaryPage({
    required this.profile,
    required this.meals,
    required this.symptoms,
    required this.days,
  });
  final ProfileSetupAnswers? profile;
  final List<AibsMealLog> meals;
  final List<AibsSymptomLog> symptoms;
  final int days;

  @override
  State<_ConsultationSummaryPage> createState() =>
      _ConsultationSummaryPageState();
}

class _ConsultationSummaryPageState extends State<_ConsultationSummaryPage> {
  bool _exporting = false;
  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final bytes = await consultationPdf(
        days: widget.days,
        directive: widget.profile?.dietType ?? 'Belum diisi',
        meals: widget.meals,
        symptoms: widget.symptoms,
        questions: _questions,
      );
      await exportFile(bytes, 'aibs-konsultasi.pdf', 'application/pdf');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppServices.message(error))));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  final _questionController = TextEditingController();
  final _questions = <String>[
    'Apa yang perlu saya perhatikan dari catatan ini?',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final summary = StringBuffer()
      ..writeln('Ringkasan konsultasi AIBS')
      ..writeln('Arahan makan: ${profile?.dietType ?? 'Belum diisi'}')
      ..writeln('Catatan makan: ${widget.meals.length}')
      ..writeln('Gejala: ${widget.symptoms.length}')
      ..writeln('Belum tentu penyebab');
    return Scaffold(
      appBar: AppBar(title: const Text('Buat konsultasi')),
      body: ListView(
        padding: const EdgeInsets.all(AibsSpace.s20),
        children: [
          AibsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow('Periode', '${widget.days} hari terakhir'),
                _summaryRow('Arahan', profile?.dietType ?? 'Belum diisi'),
                _summaryRow(
                  'Alergi',
                  profile?.allergies.isNotEmpty == true
                      ? profile!.allergies.join(' · ')
                      : 'Belum diisi',
                ),
              ],
            ),
          ),
          const SizedBox(height: AibsSpace.s16),
          Text('Gejala & makanan sebelumnya', style: AibsType.sectionTitle),
          const SizedBox(height: AibsSpace.s8),
          for (final symptom in widget.symptoms)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _SeverityDot(value: symptom.severity),
              title: Text('${symptom.name} · ${symptom.time}'),
              subtitle: Text(
                symptom.mealName == null
                    ? 'Belum ada makanan yang dihubungkan'
                    : 'Setelah ${symptom.mealName}',
              ),
            ),
          const SizedBox(height: AibsSpace.s16),
          Text('Pertanyaan buat dokter', style: AibsType.sectionTitle),
          for (final question in _questions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(question),
              trailing: IconButton(
                tooltip: 'Hapus pertanyaan',
                onPressed: () => setState(() => _questions.remove(question)),
                icon: const Icon(Icons.close),
              ),
            ),
          TextField(
            controller: _questionController,
            decoration: InputDecoration(
              hintText: 'Tambah pertanyaan',
              suffixIcon: IconButton(
                tooltip: 'Tambah pertanyaan',
                onPressed: _addQuestion,
                icon: const Icon(Icons.add),
              ),
            ),
            onSubmitted: (_) => _addQuestion(),
          ),
          const SizedBox(height: AibsSpace.s20),
          AibsPrimaryButton(
            label: _exporting ? 'Menyiapkan PDF...' : 'Unduh / bagikan PDF',
            onPressed: _exporting ? null : _export,
          ),
          const SizedBox(height: AibsSpace.s12),
          AibsSecondaryButton(
            label: 'Salin ringkasan',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: '${summary.toString()}\n${_questions.join('\n')}',
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ringkasan disalin')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AibsSpace.s12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AibsType.small),
        Text(value, style: AibsType.bodyStrong),
      ],
    ),
  );

  void _addQuestion() {
    final value = _questionController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _questions.add(value);
      _questionController.clear();
    });
  }
}

class _SeverityDot extends StatelessWidget {
  const _SeverityDot({required this.value});
  final int? value;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 20,
    backgroundColor: AibsColors.primarySoft,
    child: Text(value?.toString() ?? '?', style: AibsType.bodyStrong),
  );
}

String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
][month - 1];
