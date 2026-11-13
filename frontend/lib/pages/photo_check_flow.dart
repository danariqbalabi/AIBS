import 'package:flutter/material.dart';

import '../core/theme/aibs_tokens.dart';
import '../shared/widgets/koala.dart';
import '../shared/widgets/status_badge.dart';
import '../theme/aibs_theme.dart';
import '../widgets/aibs_widgets.dart';

enum FoodCheckIntent { checkBeforeMeal, alreadyEaten }

class FoodCheckDraft {
  const FoodCheckDraft({required this.name, required this.ingredients});

  final String name;
  final List<FoodIngredient> ingredients;
}

class FoodIngredient {
  const FoodIngredient({
    required this.name,
    required this.amount,
    this.isUnknown = false,
  });

  final String name;
  final String amount;
  final bool isUnknown;
}

class FoodCheckOutcome {
  const FoodCheckOutcome({
    required this.status,
    required this.headline,
    required this.reason,
  });

  final CheckStatus status;
  final String headline;
  final String reason;
}

class FoodCheckException implements Exception {
  const FoodCheckException(this.message);

  final String message;
}

typedef PhotoAnalyzer = Future<FoodCheckDraft> Function();
typedef FoodChecker = Future<FoodCheckOutcome> Function(FoodCheckDraft draft);
typedef FoodRecordSaver = void Function(FoodCheckDraft draft);

enum _FoodFlowStep {
  camera,
  preview,
  processing,
  failed,
  manual,
  review,
  clarification,
  result,
  saved,
}

enum _RetryAction { photo, check, save }

class CameraFlowPage extends StatefulWidget {
  const CameraFlowPage({
    required this.intent,
    super.key,
    this.initialManualEntry = false,
    this.aiEnabled = false,
    this.onAnalyzePhoto,
    this.onCheckFood,
    this.onSaveRecord,
    this.onOpenMenu,
    this.onAddSymptom,
  });

  final FoodCheckIntent intent;
  final bool initialManualEntry;
  final bool aiEnabled;
  final PhotoAnalyzer? onAnalyzePhoto;
  final FoodChecker? onCheckFood;
  final FoodRecordSaver? onSaveRecord;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onAddSymptom;

  @override
  State<CameraFlowPage> createState() => _CameraFlowPageState();
}

class _CameraFlowPageState extends State<CameraFlowPage> {
  final _foodController = TextEditingController();
  final _newIngredientController = TextEditingController();
  final _customSpiceController = TextEditingController();
  final _ingredients = <FoodIngredient>[
    const FoodIngredient(name: 'Nasi putih', amount: '1 porsi'),
    const FoodIngredient(name: 'Ayam goreng', amount: '1 potong'),
    const FoodIngredient(name: 'Saus', amount: 'belum jelas', isUnknown: true),
  ];
  final _otherSauceIngredients = <String>{};

  late _FoodFlowStep _step;
  _FoodFlowStep _manualReturnStep = _FoodFlowStep.camera;
  _FoodFlowStep _reviewBackStep = _FoodFlowStep.preview;
  String _failureMessage = 'Analisis foto belum tersedia.';
  String _failureTitle = 'Fotonya belum bisa dibaca';
  String? _sauceError;
  String? _foodNameError;
  String? _selectedSauce;
  FoodCheckOutcome? _outcome;
  TimeOfDay _mealTime = TimeOfDay.now();
  bool _isBusy = false;
  bool _hasPhoto = false;
  int _operationId = 0;
  _RetryAction _retryAction = _RetryAction.photo;

  static const _sauceOptions = [
    'Kecap manis',
    'Sambal',
    'Saus tiram',
    'Saus tomat',
    '? Nggak tahu',
  ];

  static const _spiceOptions = ['Bawang putih', 'Bawang bombay', 'Cabai'];

  @override
  void initState() {
    super.initState();
    _step = widget.initialManualEntry
        ? _FoodFlowStep.manual
        : _FoodFlowStep.camera;
  }

  @override
  void dispose() {
    _foodController.dispose();
    _newIngredientController.dispose();
    _customSpiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (_step) {
    _FoodFlowStep.camera => _buildCamera(),
    _FoodFlowStep.preview => _buildPreview(),
    _FoodFlowStep.processing => _buildProcessing(),
    _FoodFlowStep.failed => _buildFailure(),
    _FoodFlowStep.manual => _buildManualEntry(),
    _FoodFlowStep.review => _buildReview(),
    _FoodFlowStep.clarification => _buildClarification(),
    _FoodFlowStep.result => _buildResult(),
    _FoodFlowStep.saved => _buildSaved(),
  };

  Widget _buildCamera() {
    return ColoredBox(
      color: AibsColors.ink,
      child: SafeArea(
        child: Column(
          children: [
            _topBar(
              '',
              onBack: _close,
              dark: true,
              backIcon: Icons.close,
              backTooltip: 'Tutup',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AibsSpace.s20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AibsColors.inkMuted,
                    borderRadius: BorderRadius.circular(AibsRadius.xl),
                    border: Border.all(
                      color: AibsColors.onPrimary.withValues(alpha: 0.6),
                      width: AibsSpace.s2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AibsColors.onPrimary,
                      size: AibsSize.cameraButton,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s24),
              child: Text(
                'Foto dari atas, semua lauk kelihatan',
                textAlign: TextAlign.center,
                style: AibsType.body.copyWith(color: AibsColors.onPrimary),
              ),
            ),
            Padding(
              padding: AibsSpace.bottomActions,
              child: Column(
                children: [
                  AibsPrimaryButton(
                    label: 'Ambil foto',
                    icon: Icons.camera_alt_outlined,
                    onPressed: () => setState(() {
                      _hasPhoto = true;
                      _step = _FoodFlowStep.preview;
                      _mealTime = TimeOfDay.now();
                    }),
                  ),
                  const SizedBox(height: AibsSpace.s8),
                  AibsSecondaryButton(
                    label: 'Pilih dari galeri',
                    onPressed: () => setState(() {
                      _hasPhoto = true;
                      _step = _FoodFlowStep.preview;
                      _mealTime = TimeOfDay.now();
                    }),
                  ),
                  TextButton(
                    onPressed: () => _openManual(_FoodFlowStep.camera),
                    child: Text(
                      'Isi manual',
                      style: AibsType.label.copyWith(
                        color: AibsColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return _contentPage(
      title: 'Foto makanan',
      onBack: () => setState(() => _step = _FoodFlowStep.camera),
      children: [
        Container(
          height: AibsSize.photoPreview,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AibsGradients.food(AibsColors.foodBlue),
            borderRadius: BorderRadius.circular(AibsRadius.xl),
          ),
          child: const Icon(
            Icons.rice_bowl_outlined,
            color: AibsColors.primaryStrong,
            size: AibsSize.cameraButton,
          ),
        ),
      ],
      primaryLabel: widget.aiEnabled ? 'Analisis' : 'Isi manual',
      primaryIcon: widget.aiEnabled ? Icons.auto_awesome : null,
      onPrimary: widget.aiEnabled
          ? _analyzePhoto
          : () => _openManual(_FoodFlowStep.preview),
      secondaryLabel: 'Foto ulang',
      onSecondary: () => setState(() => _step = _FoodFlowStep.camera),
    );
  }

  Widget _buildProcessing() {
    return _contentPage(
      title: '',
      onBack: _cancelProcessing,
      children: [
        const SizedBox(height: AibsSpace.s24),
        const Center(
          child: Koala(KoalaMood.mikir, size: AibsSize.koalaProcessing),
        ),
        const SizedBox(height: AibsSpace.s20),
        Text(
          'Lagi baca fotomu',
          style: AibsType.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AibsSpace.s24),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: AibsSpace.s24),
        Center(
          child: TextButton(
            onPressed: () => _openManual(_FoodFlowStep.preview),
            child: const Text('Isi manual aja'),
          ),
        ),
      ],
      primaryLabel: 'Batal',
      onPrimary: _cancelProcessing,
    );
  }

  Widget _buildFailure() {
    return _contentPage(
      title: '',
      onBack: () => setState(() => _step = _FoodFlowStep.preview),
      children: [
        const SizedBox(height: AibsSpace.s24),
        const Center(
          child: Koala(KoalaMood.mikir, size: AibsSize.koalaProcessing),
        ),
        const SizedBox(height: AibsSpace.s20),
        Text(_failureTitle, style: AibsType.title, textAlign: TextAlign.center),
        const SizedBox(height: AibsSpace.s8),
        Text(
          _failureMessage,
          style: AibsType.body,
          textAlign: TextAlign.center,
        ),
      ],
      primaryLabel: 'Coba lagi',
      onPrimary: _retry,
      secondaryLabel: 'Isi manual',
      onSecondary: () => _openManual(_FoodFlowStep.preview),
    );
  }

  Widget _buildManualEntry() {
    return _contentPage(
      title: 'Isi manual',
      onBack: _backFromManual,
      children: [
        TextField(
          controller: _foodController,
          onChanged: (_) {
            if (_foodNameError != null) {
              setState(() => _foodNameError = null);
            }
          },
          decoration: InputDecoration(
            labelText: 'Nama makanan',
            errorText: _foodNameError,
          ),
        ),
        const SizedBox(height: AibsSpace.s20),
        Text('Bahan', style: AibsType.sectionTitle),
        const SizedBox(height: AibsSpace.s12),
        AibsCard(
          child: Column(
            children: [
              for (var index = 0; index < _ingredients.length; index++) ...[
                if (index > 0) const Divider(height: AibsSpace.s20),
                _editableIngredientRow(index),
              ],
            ],
          ),
        ),
        const SizedBox(height: AibsSpace.s12),
        _addIngredientField(),
      ],
      primaryLabel: 'Lanjut',
      onPrimary: _continueFromManual,
    );
  }

  Widget _buildReview() {
    final hasUnknown = _ingredients.any((ingredient) => ingredient.isUnknown);
    final primaryLabel = hasUnknown
        ? 'Lanjut'
        : widget.intent == FoodCheckIntent.checkBeforeMeal
        ? 'Cek makanan'
        : 'Simpan';

    return _contentPage(
      title: 'Cek hasil foto',
      onBack: () => setState(() => _step = _reviewBackStep),
      children: [
        Text('Makanan', style: AibsType.caption),
        const SizedBox(height: AibsSpace.s8),
        Wrap(
          spacing: AibsSpace.s8,
          runSpacing: AibsSpace.s8,
          children: [
            for (final guess in [
              _foodController.text.trim().isEmpty
                  ? 'Nasi + ayam goreng'
                  : _foodController.text.trim(),
              'Nasi + ayam bakar',
            ])
              AibsChoiceChip(
                label: guess,
                selected: _foodController.text == guess,
                onTap: () => setState(() => _foodController.text = guess),
              ),
            AibsChoiceChip(
              label: 'Lainnya',
              selected: false,
              onTap: _editFoodName,
            ),
          ],
        ),
        const SizedBox(height: AibsSpace.s20),
        Text('Bahan yang kelihatan', style: AibsType.sectionTitle),
        const SizedBox(height: AibsSpace.s12),
        AibsCard(
          child: Column(
            children: [
              for (var index = 0; index < _ingredients.length; index++) ...[
                if (index > 0) const Divider(height: AibsSpace.s20),
                _editableIngredientRow(index),
              ],
            ],
          ),
        ),
        const SizedBox(height: AibsSpace.s12),
        _addIngredientField(),
        const SizedBox(height: AibsSpace.s20),
        _unknownIngredientsCard(),
        const SizedBox(height: AibsSpace.s20),
        _mealTimeRow(),
      ],
      primaryLabel: primaryLabel,
      onPrimary: hasUnknown
          ? () => setState(() => _step = _FoodFlowStep.clarification)
          : widget.intent == FoodCheckIntent.checkBeforeMeal
          ? _checkFood
          : _saveRecord,
    );
  }

  Widget _buildClarification() {
    return _contentPage(
      title: 'Perlu konfirmasi',
      onBack: () => setState(() => _step = _FoodFlowStep.review),
      children: [
        Text('Saus ini kira-kira apa?', style: AibsType.title),
        const SizedBox(height: AibsSpace.s12),
        RadioGroup<String>(
          groupValue: _selectedSauce,
          onChanged: (value) => setState(() {
            _selectedSauce = value;
            _sauceError = null;
          }),
          child: Column(
            children: [
              for (final sauce in _sauceOptions)
                Padding(
                  padding: const EdgeInsets.only(bottom: AibsSpace.s8),
                  child: Material(
                    color: AibsColors.card,
                    borderRadius: BorderRadius.circular(AibsRadius.lg),
                    child: RadioListTile<String>(
                      value: sauce,
                      activeColor: AibsColors.primary,
                      title: Text(sauce, style: AibsType.bodyStrong),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_sauceError != null) ...[
          const SizedBox(height: AibsSpace.s4),
          Text(
            _sauceError!,
            style: AibsType.caption.copyWith(color: AibsColors.badInk),
          ),
        ],
        const SizedBox(height: AibsSpace.s20),
        Text('Bumbu lain di saus', style: AibsType.sectionTitle),
        const SizedBox(height: AibsSpace.s12),
        Wrap(
          spacing: AibsSpace.s8,
          runSpacing: AibsSpace.s8,
          children: [
            for (final spice in _spiceOptions)
              AibsChoiceChip(
                label: spice,
                selected: _otherSauceIngredients.contains(spice),
                onTap: () => setState(() {
                  if (!_otherSauceIngredients.add(spice)) {
                    _otherSauceIngredients.remove(spice);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: AibsSpace.s12),
        TextField(
          controller: _customSpiceController,
          decoration: InputDecoration(
            hintText: 'Atau tulis sendiri',
            suffixIcon: IconButton(
              tooltip: 'Tambah bumbu',
              onPressed: _addCustomSpice,
              icon: const Icon(Icons.add),
            ),
          ),
          onSubmitted: (_) => _addCustomSpice(),
        ),
        if (_otherSauceIngredients.isNotEmpty) ...[
          const SizedBox(height: AibsSpace.s12),
          Wrap(
            spacing: AibsSpace.s8,
            children: [
              for (final spice in _otherSauceIngredients)
                Chip(
                  label: Text(spice),
                  onDeleted: () =>
                      setState(() => _otherSauceIngredients.remove(spice)),
                ),
            ],
          ),
        ],
      ],
      primaryLabel: widget.intent == FoodCheckIntent.checkBeforeMeal
          ? 'Cek makanan'
          : 'Simpan',
      onPrimary: _confirmIngredients,
    );
  }

  Widget _buildResult() {
    final outcome = _outcome;
    if (outcome == null) {
      return _contentPage(
        title: 'Hasil cek',
        onBack: () => setState(() => _step = _FoodFlowStep.review),
        children: [
          Text('Hasil pengecekan belum tersedia.', style: AibsType.body),
        ],
        primaryLabel: 'Kembali',
        onPrimary: () => setState(() => _step = _FoodFlowStep.review),
      );
    }

    final mood = switch (outcome.status) {
      CheckStatus.ok => KoalaMood.senang,
      CheckStatus.warn => KoalaMood.mikir,
      CheckStatus.bad => KoalaMood.khawatir,
      CheckStatus.unknown => KoalaMood.mikir,
    };
    final headlineColor = switch (outcome.status) {
      CheckStatus.ok => AibsColors.okInk,
      CheckStatus.warn => AibsColors.warnInk,
      CheckStatus.bad => AibsColors.badInk,
      CheckStatus.unknown => AibsColors.inkMuted,
    };

    return _contentPage(
      title: 'Hasil cek',
      onBack: () => setState(() => _step = _FoodFlowStep.review),
      children: [
        Row(
          children: [
            Container(
              width: AibsSize.thumb,
              height: AibsSize.thumb,
              decoration: BoxDecoration(
                gradient: AibsGradients.food(AibsColors.foodBlue),
                borderRadius: BorderRadius.circular(AibsRadius.md),
              ),
              child: const Icon(Icons.rice_bowl_outlined),
            ),
            const SizedBox(width: AibsSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentDishName,
                    style: AibsType.bodyStrong,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_hasPhoto ? 'Dari foto' : 'Isi manual'} · ${_formatTime(_mealTime)}',
                    style: AibsType.small,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AibsSpace.s16),
        VerdictCard(
          mood: mood,
          headline: outcome.headline,
          detail: outcome.reason,
          headlineColor: headlineColor,
          color: outcome.status.soft,
        ),
        const SizedBox(height: AibsSpace.s12),
        StatusBadge(outcome.status),
        const SizedBox(height: AibsSpace.s12),
        AibsCard(
          child: Column(
            children: [
              for (var index = 0; index < _ingredients.length; index++) ...[
                if (index > 0) const Divider(height: AibsSpace.s20),
                _resultIngredientRow(_ingredients[index], outcome.status),
              ],
            ],
          ),
        ),
        const SizedBox(height: AibsSpace.s12),
        Text('Belum tentu penyebab gejala.', style: AibsType.micro),
        const SizedBox(height: AibsSpace.s20),
        if (widget.onOpenMenu != null)
          AibsCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Coba ganti dengan menu lain',
                    style: AibsType.bodyStrong,
                  ),
                ),
                TextButton(
                  onPressed: widget.onOpenMenu,
                  child: const Text('Lihat menu'),
                ),
              ],
            ),
          ),
        if (_ingredients.any((ingredient) => ingredient.isUnknown)) ...[
          const SizedBox(height: AibsSpace.s12),
          AibsSecondaryButton(
            label: 'Lengkapi bahan',
            onPressed: () =>
                setState(() => _step = _FoodFlowStep.clarification),
          ),
        ],
      ],
      primaryLabel: outcome.status == CheckStatus.ok
          ? 'Catat sudah dimakan'
          : 'Tetap catat',
      onPrimary: _saveRecord,
      secondaryLabel: 'Nggak jadi',
      onSecondary: _close,
    );
  }

  Widget _buildSaved() {
    return _contentPage(
      title: '',
      onBack: _close,
      children: [
        const SizedBox(height: AibsSpace.s24),
        const Center(child: Koala(KoalaMood.senang, size: AibsSize.koalaSaved)),
        const SizedBox(height: AibsSpace.s16),
        Text('Tersimpan', style: AibsType.title, textAlign: TextAlign.center),
        const SizedBox(height: AibsSpace.s20),
        AibsCard(
          child: Row(
            children: [
              SizedBox(
                width: AibsSize.logTime,
                child: Text(_formatTime(_mealTime), style: AibsType.small),
              ),
              Expanded(
                child: Text(_currentDishName, style: AibsType.bodyStrong),
              ),
              Text(_mealLabel(_mealTime), style: AibsType.caption),
            ],
          ),
        ),
      ],
      primaryLabel: 'Selesai',
      onPrimary: _close,
      secondaryLabel: 'Ada keluhan',
      onSecondary: _openSymptomJournal,
    );
  }

  Widget _contentPage({
    required String title,
    required List<Widget> children,
    required String primaryLabel,
    required VoidCallback onPrimary,
    VoidCallback? onBack,
    IconData? primaryIcon,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return ColoredBox(
      color: AibsColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            _topBar(title, onBack: onBack),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AibsSpace.s20,
                  AibsSpace.s16,
                  AibsSpace.s20,
                  AibsSpace.s24,
                ),
                children: children,
              ),
            ),
            _stickyActions(
              primaryLabel: primaryLabel,
              onPrimary: onPrimary,
              primaryIcon: primaryIcon,
              secondaryLabel: secondaryLabel,
              onSecondary: onSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(
    String title, {
    VoidCallback? onBack,
    bool dark = false,
    IconData backIcon = Icons.arrow_back,
    String backTooltip = 'Kembali',
  }) {
    final foreground = dark ? AibsColors.onPrimary : AibsColors.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AibsSpace.s20,
        AibsSpace.s16,
        AibsSpace.s20,
        AibsSpace.s8,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AibsSize.backButton,
            height: AibsSize.backButton,
            child: IconButton(
              tooltip: backTooltip,
              onPressed: onBack ?? _close,
              style: IconButton.styleFrom(
                backgroundColor: dark ? AibsColors.inkMuted : AibsColors.card,
                foregroundColor: foreground,
              ),
              icon: Icon(backIcon),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AibsType.verdict.copyWith(color: foreground),
            ),
          ),
          const SizedBox(width: AibsSize.backButton),
        ],
      ),
    );
  }

  Widget _stickyActions({
    required String primaryLabel,
    required VoidCallback onPrimary,
    IconData? primaryIcon,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AibsColors.card,
        boxShadow: AibsShadows.bar,
      ),
      child: Padding(
        padding: AibsSpace.bottomActions,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AibsPrimaryButton(
              label: primaryLabel,
              icon: primaryIcon,
              onPressed: _isBusy ? null : onPrimary,
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: AibsSpace.s8),
              IgnorePointer(
                ignoring: _isBusy,
                child: AibsSecondaryButton(
                  label: secondaryLabel,
                  onPressed: onSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _editableIngredientRow(int index) {
    final ingredient = _ingredients[index];
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AibsSize.ingredientRow),
      child: Row(
        children: [
          if (ingredient.isUnknown) ...[
            const StatusDot(CheckStatus.unknown, size: AibsSize.navIcon),
            const SizedBox(width: AibsSpace.s8),
          ],
          Expanded(
            child: Text(
              ingredient.name,
              style: AibsType.bodyStrong.copyWith(
                color: ingredient.isUnknown ? AibsColors.inkMuted : null,
              ),
            ),
          ),
          Text(ingredient.amount, style: AibsType.caption),
          IconButton(
            tooltip: 'Hapus ${ingredient.name}',
            onPressed: () => setState(() => _ingredients.removeAt(index)),
            icon: const Icon(Icons.close, size: AibsSize.navIcon),
          ),
        ],
      ),
    );
  }

  Widget _addIngredientField() {
    return TextField(
      controller: _newIngredientController,
      decoration: InputDecoration(
        hintText: 'Tambah bahan',
        prefixIcon: const Icon(Icons.add),
        suffixIcon: IconButton(
          tooltip: 'Tambah bahan',
          onPressed: _addIngredient,
          icon: const Icon(Icons.arrow_forward),
        ),
      ),
      onSubmitted: (_) => _addIngredient(),
    );
  }

  Widget _unknownIngredientsCard() {
    final unknown = _ingredients
        .where((ingredient) => ingredient.isUnknown)
        .toList();
    if (unknown.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Belum jelas', style: AibsType.sectionTitle),
        const SizedBox(height: AibsSpace.s8),
        for (final ingredient in unknown)
          Material(
            color: AibsColors.unknownSoft,
            borderRadius: BorderRadius.circular(AibsRadius.lg),
            child: InkWell(
              onTap: () => setState(() => _step = _FoodFlowStep.clarification),
              borderRadius: BorderRadius.circular(AibsRadius.lg),
              child: Padding(
                padding: const EdgeInsets.all(AibsSpace.s12),
                child: Row(
                  children: [
                    const StatusDot(CheckStatus.unknown),
                    const SizedBox(width: AibsSpace.s8),
                    Expanded(
                      child: Text(ingredient.name, style: AibsType.bodyStrong),
                    ),
                    const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _mealTimeRow() {
    return AibsCard(
      child: InkWell(
        onTap: _selectMealTime,
        child: Row(
          children: [
            const Icon(Icons.schedule, color: AibsColors.primaryStrong),
            const SizedBox(width: AibsSpace.s12),
            Expanded(child: Text('Waktu makan', style: AibsType.bodyStrong)),
            Text(_formatTime(_mealTime), style: AibsType.button),
            const SizedBox(width: AibsSpace.s8),
            const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
          ],
        ),
      ),
    );
  }

  Widget _resultIngredientRow(FoodIngredient ingredient, CheckStatus status) {
    final ingredientStatus = ingredient.isUnknown
        ? CheckStatus.unknown
        : status;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AibsSize.ingredientRow),
      child: Row(
        children: [
          StatusDot(ingredientStatus),
          const SizedBox(width: AibsSpace.s12),
          Expanded(child: Text(ingredient.name, style: AibsType.bodyStrong)),
          Text(ingredient.amount, style: AibsType.caption),
        ],
      ),
    );
  }

  void _openManual(_FoodFlowStep returnStep) {
    _operationId++;
    setState(() {
      _isBusy = false;
      _manualReturnStep = returnStep;
      _step = _FoodFlowStep.manual;
    });
  }

  void _backFromManual() {
    if (widget.initialManualEntry &&
        _manualReturnStep == _FoodFlowStep.camera) {
      _close();
      return;
    }
    setState(() => _step = _manualReturnStep);
  }

  void _cancelProcessing() {
    _operationId++;
    setState(() {
      _isBusy = false;
      _step = _FoodFlowStep.preview;
    });
  }

  void _continueFromManual() {
    if (_foodController.text.trim().isEmpty) {
      setState(() => _foodNameError = 'Isi nama makanan');
      return;
    }
    setState(() {
      _foodNameError = null;
      _reviewBackStep = _FoodFlowStep.manual;
      _step = _ingredients.any((ingredient) => ingredient.isUnknown)
          ? _FoodFlowStep.clarification
          : _FoodFlowStep.review;
    });
  }

  Future<void> _analyzePhoto() async {
    final analyzer = widget.onAnalyzePhoto;
    if (!widget.aiEnabled || analyzer == null) {
      setState(() {
        _retryAction = _RetryAction.photo;
        _failureTitle = 'Fotonya belum bisa dibaca';
        _failureMessage = !widget.aiEnabled
            ? 'Bantuan AI belum diaktifkan.'
            : 'Analisis foto belum terhubung.';
        _step = _FoodFlowStep.failed;
      });
      return;
    }

    final operationId = ++_operationId;
    setState(() {
      _isBusy = true;
      _step = _FoodFlowStep.processing;
    });
    try {
      final draft = await analyzer();
      if (!mounted || operationId != _operationId) return;
      if (draft.name.trim().isEmpty || draft.ingredients.isEmpty) {
        setState(() {
          _isBusy = false;
          _retryAction = _RetryAction.photo;
          _failureTitle = 'Fotonya belum bisa dibaca';
          _failureMessage = 'Belum ada bahan yang bisa dikonfirmasi.';
          _step = _FoodFlowStep.failed;
        });
        return;
      }
      setState(() {
        _foodController.text = draft.name;
        _ingredients
          ..clear()
          ..addAll(draft.ingredients);
        _reviewBackStep = _FoodFlowStep.preview;
        _isBusy = false;
        _step = _FoodFlowStep.review;
      });
    } on FoodCheckException catch (error) {
      if (!mounted || operationId != _operationId) return;
      setState(() {
        _isBusy = false;
        _retryAction = _RetryAction.photo;
        _failureTitle = 'Fotonya belum bisa dibaca';
        _failureMessage = error.message;
        _step = _FoodFlowStep.failed;
      });
    }
  }

  Future<void> _checkFood() async {
    final foodName = _currentDishName;
    final draft = FoodCheckDraft(
      name: foodName,
      ingredients: List.unmodifiable(_ingredients),
    );
    final checker = widget.onCheckFood;
    if (checker == null) {
      setState(() {
        _outcome = const FoodCheckOutcome(
          status: CheckStatus.unknown,
          headline: 'Belum bisa dinilai',
          reason: 'Hasil cek belum tersedia.',
        );
        _step = _FoodFlowStep.result;
      });
      return;
    }

    final operationId = ++_operationId;
    setState(() => _isBusy = true);
    try {
      final result = await checker(draft);
      if (!mounted || operationId != _operationId) return;
      setState(() {
        _outcome = result;
        _isBusy = false;
        _step = _FoodFlowStep.result;
      });
    } on FoodCheckException catch (error) {
      if (!mounted || operationId != _operationId) return;
      setState(() {
        _isBusy = false;
        _failureTitle = 'Pengecekan belum selesai';
        _retryAction = _RetryAction.check;
        _failureMessage = error.message;
        _step = _FoodFlowStep.failed;
      });
    }
  }

  void _confirmIngredients() {
    final selectedSauce = _selectedSauce;
    if (selectedSauce == null) {
      setState(() => _sauceError = 'Pilih saus atau pilih Nggak tahu.');
      return;
    }

    if (selectedSauce != '? Nggak tahu') {
      final index = _ingredients.indexWhere(
        (ingredient) => ingredient.isUnknown,
      );
      if (index != -1) {
        _ingredients[index] = FoodIngredient(
          name: selectedSauce,
          amount: 'secukupnya',
        );
      }
    }
    for (final spice in _otherSauceIngredients) {
      if (!_ingredients.any((ingredient) => ingredient.name == spice)) {
        _ingredients.add(FoodIngredient(name: spice, amount: 'secukupnya'));
      }
    }
    setState(() {});
    if (widget.intent == FoodCheckIntent.alreadyEaten) {
      _saveRecord();
    } else {
      _checkFood();
    }
  }

  void _saveRecord() {
    final saver = widget.onSaveRecord;
    if (saver == null) {
      setState(() {
        _failureTitle = 'Catatan belum tersimpan';
        _failureMessage = 'Penyimpanan catatan belum tersedia.';
        _retryAction = _RetryAction.save;
        _step = _FoodFlowStep.failed;
      });
      return;
    }

    saver(
      FoodCheckDraft(
        name: _currentDishName,
        ingredients: List.unmodifiable(_ingredients),
      ),
    );
    setState(() => _step = _FoodFlowStep.saved);
  }

  void _retry() {
    switch (_retryAction) {
      case _RetryAction.photo:
        setState(() => _step = _FoodFlowStep.camera);
        return;
      case _RetryAction.check:
        setState(() => _step = _FoodFlowStep.review);
        _checkFood();
        return;
      case _RetryAction.save:
        _saveRecord();
        return;
    }
  }

  void _addIngredient() {
    final name = _newIngredientController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _ingredients.add(FoodIngredient(name: name, amount: 'secukupnya'));
      _newIngredientController.clear();
    });
  }

  void _addCustomSpice() {
    final spice = _customSpiceController.text.trim();
    if (spice.isEmpty) return;
    setState(() {
      _otherSauceIngredients.add(spice);
      _customSpiceController.clear();
    });
  }

  Future<void> _editFoodName() async {
    final controller = TextEditingController(text: _currentDishName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nama makanan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    setState(() => _foodController.text = name);
  }

  Future<void> _selectMealTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _mealTime,
    );
    if (selected == null || !mounted) return;
    setState(() => _mealTime = selected);
  }

  String get _currentDishName {
    final name = _foodController.text.trim();
    return name.isEmpty ? 'Nasi + ayam goreng' : name;
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}.'
      '${time.minute.toString().padLeft(2, '0')}';

  String _mealLabel(TimeOfDay time) {
    if (time.hour >= 5 && time.hour < 11) return 'Sarapan';
    if (time.hour >= 11 && time.hour < 15) return 'Siang';
    if (time.hour >= 15 && time.hour < 18) return 'Camilan';
    return 'Malam';
  }

  void _openSymptomJournal() {
    final onAddSymptom = widget.onAddSymptom;
    if (onAddSymptom == null) {
      _close();
      return;
    }
    onAddSymptom();
  }

  void _close() {
    _operationId++;
    Navigator.of(context).pop();
  }
}
