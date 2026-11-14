import 'dart:async';

import 'package:uuid/uuid.dart';

import '../data/app_services.dart';
import '../data/records_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/demo_data.dart';
import '../core/theme/aibs_tokens.dart';
import '../shared/widgets/koala.dart';
import '../shared/widgets/status_badge.dart';
import '../widgets/aibs_widgets.dart';

enum MealIntent { check, eaten }

enum _CameraStep {
  camera,
  preview,
  processing,
  failed,
  manual,
  clarify,
  result,
  saved,
}

class CameraFlowPage extends StatefulWidget {
  const CameraFlowPage({
    required this.onSaved,
    required this.onAddSymptom,
    this.onFinish,
    super.key,
    this.initialManualEntry = false,
    this.intent = MealIntent.check,
    this.aiEnabled = true,
    this.initialFoodName,
    this.initialIngredients = const [],
    this.onCheckFood,
  });

  final FutureOr<void> Function(AibsMealLog) onSaved;
  final VoidCallback onAddSymptom;
  final VoidCallback? onFinish;
  final bool initialManualEntry;
  final MealIntent intent;
  final bool aiEnabled;
  final String? initialFoodName;
  final List<String> initialIngredients;
  final Future<Map<String, dynamic>> Function(List<String>, bool)? onCheckFood;

  @override
  State<CameraFlowPage> createState() => _CameraFlowPageState();
}

class _CameraFlowPageState extends State<CameraFlowPage> {
  late _CameraStep _step;
  late final TextEditingController _foodController;
  final _ingredientController = TextEditingController();
  late final List<String> _ingredients;
  String _clarification = 'Nggak tahu';
  bool _unknownIngredient = true;
  AibsMealLog? _savedMeal;
  AibsMealLog? _pendingMeal;
  final _requestId = const Uuid().v4();
  bool _saving = false;
  bool _checking = false;
  Map<String, dynamic>? _evaluation;

  @override
  void initState() {
    super.initState();
    _step = widget.initialManualEntry ? _CameraStep.manual : _CameraStep.camera;
    _foodController = TextEditingController(text: widget.initialFoodName ?? '');
    _ingredients = [...widget.initialIngredients];
    _unknownIngredient = _ingredients.isEmpty;
  }

  @override
  void dispose() {
    _foodController.dispose();
    _ingredientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _step == _CameraStep.camera
          ? AibsColors.ink
          : AibsColors.surface,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? AibsMotion.reduced
              : AibsMotion.page,
          child: switch (_step) {
            _CameraStep.camera => _buildCamera(),
            _CameraStep.preview => _buildPreview(),
            _CameraStep.processing => _buildProcessing(),
            _CameraStep.failed => _buildFailure(),
            _CameraStep.manual => _buildManualEntry(),
            _CameraStep.clarify => _buildClarification(),
            _CameraStep.result => _buildResult(),
            _CameraStep.saved => _buildSaved(),
          },
        ),
      ),
    );
  }

  Widget _buildCamera() {
    return Column(
      children: [
        _PhotoTopBar(
          title: '',
          light: true,
          onBack: () => Navigator.pop(context),
        ),
        const Spacer(),
        const Icon(Icons.camera_alt_outlined, size: 72, color: Colors.white70),
        const SizedBox(height: AibsSpace.s20),
        Text(
          'Foto dari atas, semua lauk kelihatan',
          textAlign: TextAlign.center,
          style: AibsType.bodyStrong.copyWith(color: AibsColors.onPrimary),
        ),
        const Spacer(),
        Padding(
          padding: AibsSpace.bottomActions,
          child: Column(
            children: [
              AibsPrimaryButton(
                label: 'Ambil foto',
                icon: Icons.camera_alt_outlined,
                onPressed: () => setState(() => _step = _CameraStep.preview),
              ),
              const SizedBox(height: AibsSpace.s8),
              TextButton(
                onPressed: () => setState(() => _step = _CameraStep.preview),
                child: Text(
                  'Pilih dari galeri',
                  style: AibsType.label.copyWith(color: AibsColors.onPrimary),
                ),
              ),
              TextButton(
                onPressed: _openManual,
                child: Text(
                  'Isi manual',
                  style: AibsType.label.copyWith(color: AibsColors.onPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        _PhotoTopBar(
          title: 'Pratinjau foto',
          onBack: () => setState(() => _step = _CameraStep.camera),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AibsSpace.s20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AibsGradients.food(AibsColors.foodBlue),
                borderRadius: BorderRadius.circular(AibsRadius.xl),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/illustrations/bowl.svg',
                  width: 120,
                  height: 120,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: AibsSpace.bottomActions,
          child: Column(
            children: [
              AibsPrimaryButton(
                label: widget.aiEnabled ? 'Analisis' : 'Isi manual',
                icon: widget.aiEnabled ? Icons.auto_awesome : Icons.edit,
                onPressed: widget.aiEnabled ? _analyze : _openManual,
              ),
              const SizedBox(height: AibsSpace.s8),
              AibsSecondaryButton(
                label: 'Foto ulang',
                onPressed: () => setState(() => _step = _CameraStep.camera),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessing() {
    return Padding(
      padding: AibsSpace.screen,
      child: Column(
        children: [
          _PhotoTopBar(
            title: '',
            onBack: () => setState(() => _step = _CameraStep.preview),
          ),
          const Spacer(),
          const Koala(KoalaMood.mikir, size: AibsSize.koalaHelp),
          const SizedBox(height: AibsSpace.s20),
          Text('Lagi baca fotomu', style: AibsType.title),
          const SizedBox(height: AibsSpace.s20),
          const CircularProgressIndicator(),
          const Spacer(),
          TextButton(
            onPressed: _openManual,
            child: const Text('Isi manual aja'),
          ),
        ],
      ),
    );
  }

  Widget _buildFailure() {
    return Padding(
      padding: AibsSpace.screen,
      child: Column(
        children: [
          _PhotoTopBar(
            title: '',
            onBack: () => setState(() => _step = _CameraStep.preview),
          ),
          const Spacer(),
          const Koala(KoalaMood.mikir, size: AibsSize.koalaHelp),
          const SizedBox(height: AibsSpace.s16),
          Text(
            'Fotonya belum bisa dibaca',
            style: AibsType.title,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          AibsSecondaryButton(label: 'Isi manual', onPressed: _openManual),
          const SizedBox(height: AibsSpace.s10),
          AibsPrimaryButton(
            label: 'Coba lagi',
            onPressed: () => setState(() => _step = _CameraStep.camera),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntry() {
    return Column(
      children: [
        _PhotoTopBar(
          title: 'Isi manual',
          onBack: () => setState(() => _step = _CameraStep.camera),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AibsSpace.s20,
              AibsSpace.s12,
              AibsSpace.s20,
              AibsSpace.s20,
            ),
            children: [
              TextField(
                controller: _foodController,
                decoration: const InputDecoration(labelText: 'Nama makanan'),
              ),
              const SizedBox(height: AibsSpace.s20),
              Row(
                children: [
                  Expanded(child: Text('Bahan', style: AibsType.sectionTitle)),
                  TextButton(
                    onPressed: _addIngredient,
                    child: const Text('Tambah bahan'),
                  ),
                ],
              ),
              TextField(
                controller: _ingredientController,
                decoration: InputDecoration(
                  hintText: 'Nama bahan',
                  suffixIcon: IconButton(
                    tooltip: 'Tambah bahan',
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add),
                  ),
                ),
                onSubmitted: (_) => _addIngredient(),
              ),
              const SizedBox(height: AibsSpace.s12),
              AibsCard(
                child: Column(
                  children: [
                    for (final (index, ingredient) in _ingredients.indexed) ...[
                      if (index > 0) const Divider(height: AibsSpace.s16),
                      _EditableIngredient(
                        name: ingredient,
                        onRemove: () =>
                            setState(() => _ingredients.removeAt(index)),
                      ),
                    ],
                    if (_ingredients.isEmpty) ...[
                      const _UnknownIngredientRow(),
                      const SizedBox(height: AibsSpace.s8),
                      Text(
                        'Belum ada bahan yang ditambahkan.',
                        style: AibsType.caption,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AibsSpace.s12),
              if (_unknownIngredient) const _UnknownIngredientRow(),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: AibsSpace.bottomActions,
            child: AibsPrimaryButton(
              label: widget.intent == MealIntent.eaten ? 'Simpan' : 'Lanjut',
              onPressed: _continueManual,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClarification() {
    const choices = [
      'Kecap manis',
      'Sambal',
      'Saus tiram',
      'Saus tomat',
      'Nggak tahu',
    ];
    return Column(
      children: [
        _PhotoTopBar(
          title: 'Konfirmasi bahan',
          onBack: () => setState(() => _step = _CameraStep.manual),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AibsSpace.s20),
            children: [
              Text('Saus ini kira-kira apa?', style: AibsType.title),
              const SizedBox(height: AibsSpace.s16),
              for (final choice in choices)
                _RadioOption(
                  label: choice,
                  selected: _clarification == choice,
                  onTap: () => setState(() => _clarification = choice),
                ),
              const SizedBox(height: AibsSpace.s16),
              Text('Bumbu lain di saus', style: AibsType.sectionTitle),
              const SizedBox(height: AibsSpace.s8),
              AibsChoiceChip(
                label: 'Bawang putih',
                selected: _clarification == 'Bawang putih',
                onTap: () => setState(() => _clarification = 'Bawang putih'),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: AibsSpace.bottomActions,
            child: AibsPrimaryButton(
              label: widget.intent == MealIntent.eaten
                  ? 'Simpan'
                  : 'Cek makanan',
              onPressed: () {
                _unknownIngredient = _clarification == 'Nggak tahu';
                if (!_unknownIngredient &&
                    !_ingredients.contains(_clarification)) {
                  _ingredients.add(_clarification);
                }
                if (widget.intent == MealIntent.eaten) {
                  _saveMeal();
                } else {
                  _checkResult();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final status = statusFor(_evaluation?['status']);
    final reasons = (_evaluation?['reasons'] as List? ?? [])
        .map((r) => r['message'].toString())
        .toList();
    final missing = (_evaluation?['missing_information'] as List? ?? [])
        .cast<String>();
    return Column(
      children: [
        const _PhotoTopBar(title: 'Hasil cek'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AibsSpace.s20),
            children: [
              Text(
                _foodController.text.trim().isEmpty
                    ? 'Makanan dari foto'
                    : _foodController.text.trim(),
                style: AibsType.titleDetail,
              ),
              const SizedBox(height: AibsSpace.s16),
              VerdictCard(
                mood: status == CheckStatus.bad
                    ? KoalaMood.khawatir
                    : status == CheckStatus.ok
                    ? KoalaMood.senang
                    : KoalaMood.mikir,
                label: 'Hasil cek',
                headline: status.groupLabel,
                detail:
                    [...reasons, ...missing].firstOrNull ??
                    (_evaluation == null
                        ? 'Hasil pengecekan belum tersedia.'
                        : 'Mengikuti arahan yang tersimpan.'),
                color: status.soft,
                headlineColor: status.ink,
              ),
              const SizedBox(height: AibsSpace.s16),
              StatusBadge(status),
              const SizedBox(height: AibsSpace.s12),
              const Text('Belum tentu penyebab gejala.'),
              const SizedBox(height: AibsSpace.s20),
              AibsSecondaryButton(
                label: 'Lengkapi bahan',
                onPressed: () => setState(() => _step = _CameraStep.clarify),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: AibsSpace.bottomActions,
            child: Row(
              children: [
                Expanded(
                  child: AibsSecondaryButton(
                    label: 'Nggak jadi',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AibsSpace.s10),
                Expanded(
                  flex: 2,
                  child: AibsPrimaryButton(
                    label: 'Tetap catat',
                    onPressed: _saveMeal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaved() {
    final meal = _savedMeal;
    return ListView(
      padding: const EdgeInsets.all(AibsSpace.s20),
      children: [
        const SizedBox(height: AibsSpace.s24),
        const Center(child: Koala(KoalaMood.senang, size: 160)),
        const SizedBox(height: AibsSpace.s12),
        Text('Tersimpan', style: AibsType.title, textAlign: TextAlign.center),
        if (meal != null) ...[
          const SizedBox(height: AibsSpace.s16),
          AibsCard(
            child: Row(
              children: [
                Text(meal.time, style: AibsType.bodyStrong),
                const SizedBox(width: AibsSpace.s12),
                Expanded(child: Text(meal.name, style: AibsType.bodyStrong)),
              ],
            ),
          ),
        ],
        const SizedBox(height: AibsSpace.s20),
        AibsSecondaryButton(
          label: 'Ada keluhan',
          onPressed: () {
            final onAddSymptom = widget.onAddSymptom;
            Navigator.of(context).popUntil((route) => route.isFirst);
            onAddSymptom();
          },
        ),
        const SizedBox(height: AibsSpace.s10),
        AibsPrimaryButton(
          label: 'Selesai',
          onPressed: () {
            final onFinish = widget.onFinish;
            Navigator.of(context).popUntil((route) => route.isFirst);
            onFinish?.call();
          },
        ),
      ],
    );
  }

  void _analyze() {
    setState(() => _step = _CameraStep.processing);
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted && _step == _CameraStep.processing) {
        setState(() => _step = _CameraStep.failed);
      }
    });
  }

  void _openManual() {
    setState(() {
      _step = _CameraStep.manual;
      if (_ingredients.isEmpty) _unknownIngredient = true;
    });
  }

  void _addIngredient() {
    final value = _ingredientController.text.trim();
    if (value.isEmpty || _ingredients.contains(value)) return;
    setState(() {
      _ingredients.add(value);
      _ingredientController.clear();
      _unknownIngredient = false;
    });
  }

  void _continueManual() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_foodController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi nama makanan dulu.')));
      return;
    }
    if (widget.intent == MealIntent.eaten) {
      _saveMeal();
    } else if (_unknownIngredient || _ingredients.isEmpty) {
      setState(() => _step = _CameraStep.clarify);
    } else {
      _checkResult();
    }
  }

  Future<void> _checkResult() async {
    if (_checking) return;
    _checking = true;
    try {
      final evaluation = await widget.onCheckFood?.call(
        List.unmodifiable(_ingredients),
        !_unknownIngredient,
      );
      if (mounted) {
        setState(() {
          _evaluation = evaluation;
          _step = _CameraStep.result;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppServices.message(error))));
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _saveMeal() async {
    if (_saving) return;
    _saving = true;
    final meal = AibsMealLog(
      requestId: _requestId,
      name: _foodController.text.trim().isEmpty
          ? 'Makanan'
          : _foodController.text.trim(),
      time: _pendingMeal?.time ?? TimeOfDay.now().format(context),
      date: _pendingMeal?.date ?? DateTime.now(),
      status: CheckStatus.unknown,
      ingredients: List.unmodifiable(_ingredients),
      note: _unknownIngredient ? 'Ada bahan yang belum diketahui' : null,
    );
    _pendingMeal = meal;
    try {
      await widget.onSaved(meal);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppServices.message(error))));
      }
      _saving = false;
      return;
    }
    _saving = false;
    if (!mounted) return;
    setState(() {
      _savedMeal = meal;
      _step = _CameraStep.saved;
    });
  }
}

class _PhotoTopBar extends StatelessWidget {
  const _PhotoTopBar({required this.title, this.onBack, this.light = false});
  final String title;
  final VoidCallback? onBack;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AibsSpace.s12,
        AibsSpace.s8,
        AibsSpace.s20,
        AibsSpace.s8,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Tutup',
            onPressed: onBack ?? () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: light ? AibsColors.onPrimary : AibsColors.ink,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AibsType.verdict.copyWith(
                color: light ? AibsColors.onPrimary : AibsColors.ink,
              ),
            ),
          ),
          const SizedBox(width: AibsSize.backButton),
        ],
      ),
    );
  }
}

class _EditableIngredient extends StatelessWidget {
  const _EditableIngredient({required this.name, required this.onRemove});
  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const StatusDot(CheckStatus.unknown),
        const SizedBox(width: AibsSpace.s10),
        Expanded(child: Text(name, style: AibsType.bodyStrong)),
        IconButton(
          tooltip: 'Hapus $name',
          onPressed: onRemove,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _UnknownIngredientRow extends StatelessWidget {
  const _UnknownIngredientRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AibsSpace.s12,
        vertical: AibsSpace.s8,
      ),
      decoration: BoxDecoration(
        color: AibsColors.unknownSoft,
        borderRadius: BorderRadius.circular(AibsRadius.lg),
        border: Border.all(color: AibsColors.unknown, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.help_outline, color: AibsColors.inkMuted),
          const SizedBox(width: AibsSpace.s8),
          Text('Saus · belum jelas', style: AibsType.bodyStrong),
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AibsSpace.s10),
      child: Material(
        color: AibsColors.card,
        borderRadius: BorderRadius.circular(AibsRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AibsRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AibsSpace.s12),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AibsColors.primary,
                ),
                const SizedBox(width: AibsSpace.s10),
                Text(label, style: AibsType.bodyStrong),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class JournalPage extends StatefulWidget {
  const JournalPage({
    required this.meals,
    required this.symptoms,
    required this.stories,
    required this.aiEnabled,
    required this.onAddMeal,
    required this.onAddSymptom,
    required this.onAddStory,
    required this.onDeleteMeal,
    required this.onOpenSummary,
    super.key,
  });

  final List<AibsMealLog> meals;
  final List<AibsSymptomLog> symptoms;
  final List<AibsStoryLog> stories;
  final bool aiEnabled;
  final VoidCallback onAddMeal;
  final FutureOr<void> Function(AibsSymptomLog) onAddSymptom;
  final FutureOr<void> Function(AibsStoryLog) onAddStory;
  final FutureOr<void> Function(AibsMealLog) onDeleteMeal;
  final VoidCallback onOpenSummary;

  @override
  State<JournalPage> createState() => _JournalPageState();
}

enum _JournalFilter { all, meals, symptoms }

class _JournalPageState extends State<JournalPage> {
  DateTime _selectedDate = DateTime.now();
  _JournalFilter _filter = _JournalFilter.all;
  String? _storyDraft;

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

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

  String _weekday(int weekday) => const [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ][weekday - 1];

  @override
  Widget build(BuildContext context) {
    final allRecords = <_JournalRecord>[
      for (final meal in widget.meals) _JournalRecord.meal(meal),
      for (final symptom in widget.symptoms) _JournalRecord.symptom(symptom),
      for (final story in widget.stories) _JournalRecord.story(story),
    ];
    final records = allRecords.where((record) {
      final date = record.entryDate;
      if (!_isSameDay(date, _selectedDate)) return false;
      return switch (_filter) {
        _JournalFilter.all => true,
        _JournalFilter.meals => record.meal != null,
        _JournalFilter.symptoms => record.symptom != null,
      };
    }).toList()..sort((a, b) => b.sortTime.compareTo(a.sortTime));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AibsSpace.s20,
        AibsSpace.s20,
        AibsSpace.s20,
        AibsSpace.s28,
      ),
      children: [
        Row(
          children: [
            Expanded(child: Text('Jurnal', style: AibsType.title)),
            TextButton(
              onPressed: widget.onOpenSummary,
              child: const Text('Ringkasan'),
            ),
          ],
        ),
        const SizedBox(height: AibsSpace.s12),
        Row(
          children: [
            IconButton(
              tooltip: 'Hari sebelumnya',
              onPressed: () => setState(
                () => _selectedDate = _selectedDate.subtract(
                  const Duration(days: 1),
                ),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${_weekday(_selectedDate.weekday)} · ${_selectedDate.day} ${_month(_selectedDate.month)}',
                textAlign: TextAlign.center,
                style: AibsType.bodyStrong,
              ),
            ),
            IconButton(
              tooltip: 'Hari berikutnya',
              onPressed: _isSameDay(_selectedDate, DateTime.now())
                  ? null
                  : () => setState(
                      () => _selectedDate = _selectedDate.add(
                        const Duration(days: 1),
                      ),
                    ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: AibsSpace.s8),
        Wrap(
          spacing: AibsSpace.s8,
          children: [
            for (final filter in _JournalFilter.values)
              ChoiceChip(
                label: Text(switch (filter) {
                  _JournalFilter.all => 'Semua',
                  _JournalFilter.meals => 'Makan',
                  _JournalFilter.symptoms => 'Gejala',
                }),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: AibsSpace.s16),
        if (records.isEmpty)
          AibsCard(
            child: Column(
              children: [
                const Koala(KoalaMood.mikir, size: 150),
                const SizedBox(height: AibsSpace.s8),
                Text('Belum ada catatan', style: AibsType.verdict),
                const SizedBox(height: AibsSpace.s12),
                AibsPrimaryButton(
                  label: 'Catat sekarang',
                  onPressed: () => _openRecordOptions(context),
                ),
              ],
            ),
          )
        else
          AibsCard(
            padding: AibsSpace.s12,
            child: Material(
              color: AibsColors.card,
              borderRadius: BorderRadius.circular(AibsRadius.lg),
              child: Column(
                children: [
                  for (final record in records)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(record.time, style: AibsType.small),
                      title: Text(record.title, style: AibsType.bodyStrong),
                      subtitle: record.subtitle == null
                          ? null
                          : Text(record.subtitle!, style: AibsType.caption),
                      trailing: record.meal != null
                          ? StatusBadge(record.meal!.status)
                          : record.symptom != null
                          ? _SeverityDot(value: record.symptom!.severity)
                          : const Icon(Icons.notes_outlined),
                      onTap: () => _openRecordDetail(context, record),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AibsSpace.s16),
        AibsPrimaryButton(
          label: 'Catat',
          onPressed: () => _openRecordOptions(context),
        ),
      ],
    );
  }

  Future<void> _openRecordOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AibsSpace.s20,
            AibsSpace.s8,
            AibsSpace.s20,
            AibsSpace.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mau catat apa?', style: AibsType.sheetTitle),
              const SizedBox(height: AibsSpace.s14),
              if (widget.aiEnabled && _storyDraft != null)
                _RecordOption(
                  label: 'Lanjutkan draft cerita',
                  icon: Icons.edit_note,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openStory(context, initialText: _storyDraft);
                  },
                ),
              if (widget.aiEnabled)
                _RecordOption(
                  label: 'Tulis cerita',
                  icon: Icons.edit_note,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openStory(context);
                  },
                ),
              _RecordOption(
                label: 'Catat gejala',
                icon: Icons.favorite_border,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openSymptom(context);
                },
              ),
              _RecordOption(
                label: 'Catat makan',
                icon: Icons.restaurant_outlined,
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onAddMeal();
                },
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStory(BuildContext context, {String? initialText}) async {
    final showOptionsAfterExit = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _StoryEntryPage(
          initialText: initialText ?? '',
          onDraftChanged: (draft) => setState(() => _storyDraft = draft),
          onSave: (text) async {
            await widget.onAddStory(
              AibsStoryLog(
                text: text,
                time: TimeOfDay.now().format(context),
                date: DateTime.now(),
              ),
            );
            if (!mounted || !context.mounted) return;
            setState(() => _storyDraft = null);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Catatan tersimpan')));
          },
        ),
      ),
    );
    if (showOptionsAfterExit == true && mounted && context.mounted) {
      _openRecordOptions(context);
    }
  }

  void _openSymptom(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SymptomEntryPage(meals: widget.meals, onSave: widget.onAddSymptom),
      ),
    );
  }

  void _openRecordDetail(BuildContext context, _JournalRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _JournalDetailPage(
          record: record,
          onDelete: record.meal == null
              ? null
              : () async {
                  final remove = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Hapus catatan ini?'),
                      content: Text(record.meal!.name),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Hapus'),
                        ),
                      ],
                    ),
                  );
                  if (remove != true || !context.mounted) return;
                  try {
                    await widget.onDeleteMeal(record.meal!);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppServices.message(error))),
                      );
                    }
                    return;
                  }
                  if (context.mounted) Navigator.pop(context);
                },
        ),
      ),
    );
  }
}

class _JournalRecord {
  const _JournalRecord._({this.meal, this.symptom, this.story});
  factory _JournalRecord.meal(AibsMealLog meal) => _JournalRecord._(meal: meal);
  factory _JournalRecord.symptom(AibsSymptomLog symptom) =>
      _JournalRecord._(symptom: symptom);
  factory _JournalRecord.story(AibsStoryLog story) =>
      _JournalRecord._(story: story);

  final AibsMealLog? meal;
  final AibsSymptomLog? symptom;
  final AibsStoryLog? story;
  String get title => meal?.name ?? symptom?.name ?? 'Cerita hari ini';
  String? get subtitle => meal == null
      ? symptom == null
            ? story!.text
            : 'Skala ${symptom!.severity} · stres ${symptom!.stress ?? 'belum diisi'}'
      : meal!.note;
  String get time => meal?.time ?? symptom?.time ?? story!.time;
  DateTime get sortTime {
    final date = meal?.date ?? symptom?.date ?? story!.date;
    if (!RegExp(r'\d{1,2}[:.]\d{2}').hasMatch(time)) {
      return DateUtils.dateOnly(date);
    }
    return timeForInput(date, time);
  }

  DateTime get entryDate => meal?.date ?? symptom?.date ?? story!.date;
}

class _RecordOption extends StatelessWidget {
  const _RecordOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AibsColors.primaryStrong),
      title: Text(label, style: AibsType.bodyStrong),
      trailing: const Icon(Icons.chevron_right),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AibsRadius.lg),
      ),
    );
  }
}

class _StoryEntryPage extends StatefulWidget {
  const _StoryEntryPage({
    required this.initialText,
    required this.onDraftChanged,
    required this.onSave,
  });
  final String initialText;
  final ValueChanged<String?> onDraftChanged;
  final FutureOr<void> Function(String) onSave;

  @override
  State<_StoryEntryPage> createState() => _StoryEntryPageState();
}

class _StoryEntryPageState extends State<_StoryEntryPage> {
  bool _saving = false;
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: _requestExit,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Ceritain hari ini'),
      ),
      body: PopScope<Object?>(
        canPop: _controller.text.trim().isEmpty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _showDraftOptions();
        },
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AibsSpace.s20),
                children: [
                  TextField(
                    controller: _controller,
                    minLines: 5,
                    maxLines: 9,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Ceritain hari ini',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AibsSpace.s12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Isi manual aja'),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: AibsSpace.bottomActions,
                child: AibsPrimaryButton(
                  label: 'Cek sebelum simpan',
                  onPressed: () {
                    if (_controller.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tulis cerita dulu.')),
                      );
                      return;
                    }
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (sheetContext) => SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(AibsSpace.s20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cek sebelum simpan',
                                style: AibsType.sheetTitle,
                              ),
                              const SizedBox(height: AibsSpace.s12),
                              AibsCard(child: Text(_controller.text.trim())),
                              const SizedBox(height: AibsSpace.s12),
                              AibsPrimaryButton(
                                label: 'Simpan semua',
                                onPressed: () async {
                                  if (_saving) return;
                                  _saving = true;
                                  try {
                                    await widget.onSave(
                                      _controller.text.trim(),
                                    );
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                AppServices.message(error),
                                              ),
                                            ),
                                          );
                                    }
                                    _saving = false;
                                    return;
                                  }
                                  _saving = false;
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                  if (context.mounted) Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _requestExit() {
    if (_controller.text.trim().isEmpty) {
      Navigator.pop(context);
    } else {
      _showDraftOptions();
    }
  }

  Future<void> _showDraftOptions() async {
    if (_controller.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AibsSpace.s20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ceritamu belum disimpan', style: AibsType.sheetTitle),
              const SizedBox(height: AibsSpace.s12),
              AibsPrimaryButton(
                label: 'Lanjut isi',
                onPressed: () => Navigator.pop(sheetContext),
              ),
              const SizedBox(height: AibsSpace.s8),
              Center(
                child: TextButton(
                  onPressed: () {
                    widget.onDraftChanged(_controller.text.trim());
                    Navigator.pop(sheetContext);
                    Navigator.pop(context, true);
                  },
                  child: const Text('Simpan draft'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    widget.onDraftChanged(null);
                    Navigator.pop(sheetContext);
                    Navigator.pop(context, true);
                  },
                  child: Text(
                    'Buang draft',
                    style: AibsType.label.copyWith(color: AibsColors.badInk),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SymptomEntryPage extends StatefulWidget {
  const SymptomEntryPage({
    super.key,
    required this.meals,
    required this.onSave,
  });
  final List<AibsMealLog> meals;
  final FutureOr<void> Function(AibsSymptomLog) onSave;

  @override
  State<SymptomEntryPage> createState() => _SymptomEntryPageState();
}

class _SymptomEntryPageState extends State<SymptomEntryPage> {
  static const _options = [
    'Kembung',
    'Nyeri perut',
    'Diare',
    'Sembelit',
    'Mual',
    'Lainnya',
  ];
  final _selected = <String>{};
  final _noteController = TextEditingController();
  int _severity = 2;
  String _stress = 'Sedang';
  String? _linkedMeal;
  TimeOfDay _time = TimeOfDay.now();
  bool _saving = false;
  final _requestId = const Uuid().v4();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catat gejala')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AibsSpace.s20),
              children: [
                Text('Apa yang kamu rasain?', style: AibsType.sectionTitle),
                const SizedBox(height: AibsSpace.s12),
                Wrap(
                  spacing: AibsSpace.s8,
                  runSpacing: AibsSpace.s8,
                  children: [
                    for (final option in _options)
                      AibsChoiceChip(
                        label: option,
                        selected: _selected.contains(option),
                        onTap: () => setState(() {
                          if (!_selected.add(option)) _selected.remove(option);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: AibsSpace.s20),
                Text('Seberapa ganggu?', style: AibsType.sectionTitle),
                const SizedBox(height: AibsSpace.s12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var value = 1; value <= 5; value++)
                      _ScaleDot(
                        value: value,
                        selected: _severity == value,
                        onTap: () => setState(() => _severity = value),
                      ),
                  ],
                ),
                const SizedBox(height: AibsSpace.s12),
                AibsCard(
                  child: Text(
                    '$_severity · ${_severityLabel(_severity)}',
                    style: AibsType.bodyStrong,
                  ),
                ),
                const SizedBox(height: AibsSpace.s16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mulai jam'),
                  trailing: TextButton(
                    onPressed: _pickTime,
                    child: Text(_time.format(context)),
                  ),
                ),
                Text('Stres', style: AibsType.caption),
                const SizedBox(height: AibsSpace.s8),
                Wrap(
                  spacing: AibsSpace.s8,
                  children: [
                    for (final value in ['Rendah', 'Sedang', 'Tinggi'])
                      AibsChoiceChip(
                        label: value,
                        selected: _stress == value,
                        onTap: () => setState(() => _stress = value),
                      ),
                  ],
                ),
                const SizedBox(height: AibsSpace.s16),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Catatan'),
                ),
                if (widget.meals.isNotEmpty) ...[
                  const SizedBox(height: AibsSpace.s16),
                  Text('Hubungkan makanan', style: AibsType.caption),
                  DropdownButtonFormField<String>(
                    initialValue: _linkedMeal,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Tidak dihubungkan'),
                      ),
                      for (final meal in widget.meals)
                        DropdownMenuItem(
                          value: meal.id ?? meal.name,
                          child: Text(meal.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _linkedMeal = value),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: AibsSpace.bottomActions,
              child: AibsPrimaryButton(label: 'Simpan', onPressed: _save),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih gejala yang kamu rasakan.')),
      );
      return;
    }
    _saving = true;
    try {
      await widget.onSave(
        AibsSymptomLog(
          requestId: _requestId,
          mealId: widget.meals
              .where((m) => m.id == _linkedMeal)
              .firstOrNull
              ?.id,
          name: _selected.join(', '),
          time: _time.format(context),
          date: DateTime.now(),
          severity: _severity,
          stress: _stress,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          mealName: widget.meals
              .where((m) => (m.id ?? m.name) == _linkedMeal)
              .firstOrNull
              ?.name,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppServices.message(error))));
      }
      _saving = false;
      return;
    }
    _saving = false;
    if (mounted) Navigator.pop(context);
  }

  String _severityLabel(int value) => const [
    'Sangat ringan',
    'Ringan',
    'Sedang',
    'Berat',
    'Sangat berat',
  ][value - 1];
}

class _ScaleDot extends StatelessWidget {
  const _ScaleDot({
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = selected ? AibsSize.scaleDotOn : AibsSize.scaleDot;
    return Semantics(
      label: 'Skala $value',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AibsMotion.select,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? null : AibsColors.card,
            gradient: selected ? AibsGradients.brand : null,
            shape: BoxShape.circle,
            border: selected
                ? null
                : Border.all(color: AibsColors.line, width: 2),
            boxShadow: selected ? AibsShadows.glow : null,
          ),
          child: Text(
            '$value',
            style: AibsType.button.copyWith(
              color: selected ? AibsColors.onPrimary : AibsColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeverityDot extends StatelessWidget {
  const _SeverityDot({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 20,
    backgroundColor: AibsColors.primarySoft,
    child: Text('$value', style: AibsType.bodyStrong),
  );
}

class _JournalDetailPage extends StatelessWidget {
  const _JournalDetailPage({required this.record, this.onDelete});
  final _JournalRecord record;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final meal = record.meal;
    final symptom = record.symptom;
    final story = record.story;
    return Scaffold(
      appBar: AppBar(title: const Text('Detail catatan')),
      body: ListView(
        padding: const EdgeInsets.all(AibsSpace.s20),
        children: [
          Text(
            meal != null
                ? 'Makan · ${record.time}'
                : symptom != null
                ? 'Gejala · ${record.time}'
                : 'Cerita · ${record.time}',
            style: AibsType.label,
          ),
          const SizedBox(height: AibsSpace.s8),
          Text(record.title, style: AibsType.titleDetail),
          if (story != null)
            AibsCard(child: Text(story.text, style: AibsType.bodyStrong))
          else if (meal != null) ...[
            const SizedBox(height: AibsSpace.s12),
            StatusBadge(meal.status),
            const SizedBox(height: AibsSpace.s16),
            AibsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bahan', style: AibsType.sectionTitle),
                  const SizedBox(height: AibsSpace.s8),
                  for (final ingredient in meal.ingredients) Text(ingredient),
                ],
              ),
            ),
            if (meal.note != null) ...[
              const SizedBox(height: AibsSpace.s12),
              Text(meal.note!, style: AibsType.caption),
            ],
            if (onDelete != null) ...[
              const SizedBox(height: AibsSpace.s20),
              AibsSecondaryButton(label: 'Hapus', onPressed: onDelete!),
            ],
          ] else ...[
            const SizedBox(height: AibsSpace.s12),
            AibsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seberapa ganggu?', style: AibsType.caption),
                  Text(
                    'Skala ${symptom!.severity}',
                    style: AibsType.bodyStrong,
                  ),
                  if (symptom.mealName != null) ...[
                    const SizedBox(height: AibsSpace.s12),
                    Text(
                      'Sebelum ${symptom.mealName}',
                      style: AibsType.bodyStrong,
                    ),
                    const Text('Belum tentu penyebab'),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
