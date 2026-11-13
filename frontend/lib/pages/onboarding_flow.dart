import 'package:flutter/material.dart';

import '../shared/widgets/step_progress.dart';
import '../theme/aibs_theme.dart';
import '../widgets/aibs_widgets.dart';

enum _Step {
  welcome,
  account,
  condition,
  diet,
  tracking,
  allergies,
  preferences,
  review,
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _otherAllergyController = TextEditingController();
  final _avoidedIngredients = <String>{
    'Bawang putih',
    'Bawang bombay',
    'Susu sapi',
  };
  final _allergies = <String>{};
  final _preferences = <String>{};
  _Step _step = _Step.welcome;
  String? _condition;
  String? _dietType;
  String? _budget;
  String? _spiceLevel;
  int _ricePortions = 1;
  bool _isSignIn = false;
  bool _showPassword = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ingredientController.dispose();
    _otherAllergyController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == _Step.account) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
    }
    if (_step == _Step.condition && _condition == null) {
      setState(() => _formError = 'Pilih kondisi kamu dulu.');
      return;
    }
    if (_step == _Step.review) {
      widget.onComplete();
      return;
    }
    setState(() {
      _formError = null;
      switch (_step) {
        case _Step.welcome:
          _step = _Step.account;
          break;
        case _Step.account:
          _step = _Step.condition;
          break;
        case _Step.condition:
          _step = _condition == 'Sudah didiagnosis IBS dan punya arahan makan'
              ? _Step.diet
              : _Step.tracking;
          break;
        case _Step.diet:
        case _Step.tracking:
          _step = _Step.allergies;
          break;
        case _Step.allergies:
          _step = _Step.preferences;
          break;
        case _Step.preferences:
          _step = _Step.review;
          break;
        case _Step.review:
          break;
      }
    });
  }

  void _back() {
    setState(() {
      switch (_step) {
        case _Step.welcome:
          break;
        case _Step.account:
          _step = _Step.welcome;
          break;
        case _Step.condition:
          _step = _Step.account;
          break;
        case _Step.diet:
        case _Step.tracking:
          _step = _Step.condition;
          break;
        case _Step.allergies:
          _step = _condition == 'Sudah didiagnosis IBS dan punya arahan makan'
              ? _Step.diet
              : _Step.tracking;
          break;
        case _Step.preferences:
          _step = _Step.allergies;
          break;
        case _Step.review:
          _step = _Step.preferences;
          break;
      }
    });
  }

  int? get _progressStep {
    return switch (_step) {
      _Step.condition => 1,
      _Step.diet || _Step.tracking => 2,
      _Step.allergies => 3,
      _Step.preferences => 4,
      _Step.review => 5,
      _ => null,
    };
  }

  String get _buttonLabel {
    return switch (_step) {
      _Step.welcome => 'Mulai',
      _Step.account => _isSignIn ? 'Masuk' : 'Daftar',
      _Step.review => 'Simpan profil',
      _ => 'Lanjut',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: _buildStepContent(context),
                ),
              ),
            ),
            if (_formError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(
                  _formError!,
                  style: const TextStyle(
                    color: AibsColors.badInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AibsPrimaryButton(label: _buttonLabel, onPressed: _next),
                  if (_step == _Step.allergies) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(_allergies.clear);
                        _next();
                      },
                      child: const Text('Nggak ada alergi'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final progress = _progressStep;
    if (_step == _Step.welcome) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'AIBS',
            style: TextStyle(
              color: AibsColors.primaryStrong,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 24, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
          ),
          if (progress != null) ...[
            const SizedBox(width: 8),
            Expanded(child: StepProgress(step: progress, total: 5)),
          ] else
            const Spacer(),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    return switch (_step) {
      _Step.welcome => _buildWelcome(context),
      _Step.account => _buildAccount(context),
      _Step.condition => _buildCondition(context),
      _Step.diet => _buildDiet(context),
      _Step.tracking => _buildTracking(context),
      _Step.allergies => _buildAllergies(context),
      _Step.preferences => _buildPreferences(context),
      _Step.review => _buildReview(context),
    };
  }

  Widget _buildWelcome(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Center(child: AibsMascot(expression: 'senang', size: 190)),
        const SizedBox(height: 24),
        Text(
          'Makan lebih tenang.',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'Simpan arahan makan dan catatanmu di satu tempat.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildAccount(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isSignIn ? 'Masuk' : 'Buat akun',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _modeTab(
                'Daftar',
                !_isSignIn,
                () => setState(() => _isSignIn = false),
              ),
              _modeTab(
                'Masuk',
                _isSignIn,
                () => setState(() => _isSignIn = true),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!_isSignIn) ...[
            _fieldLabel('Nama panggilan'),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'Nadia'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Isi nama panggilan kamu.'
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          _fieldLabel('Email'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'nama@email.com'),
            validator: (value) => (value == null || !value.contains('@'))
                ? 'Masukkan email yang valid.'
                : null,
          ),
          const SizedBox(height: 16),
          _fieldLabel('Password'),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              hintText: 'Minimal 8 karakter',
              suffixIcon: IconButton(
                tooltip: _showPassword
                    ? 'Sembunyikan password'
                    : 'Tampilkan password',
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            validator: (value) => (value == null || value.length < 8)
                ? 'Password minimal 8 karakter.'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCondition(BuildContext context) {
    const options = [
      'Sudah didiagnosis IBS dan punya arahan makan',
      'Sudah didiagnosis, belum ada arahan makan',
      'Belum didiagnosis, baru curiga',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kondisi kamu sekarang?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        for (final option in options) ...[
          _SelectCard(
            label: option,
            selected: _condition == option,
            onTap: () => setState(() {
              final hadDietPlan =
                  _condition == 'Sudah didiagnosis IBS dan punya arahan makan';
              final hasDietPlan =
                  option == 'Sudah didiagnosis IBS dan punya arahan makan';
              if (hadDietPlan != hasDietPlan) _dietType = null;
              _condition = option;
              _formError = null;
            }),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildDiet(BuildContext context) {
    const types = [
      'Low FODMAP · eliminasi',
      'Low FODMAP · reintroduksi',
      'Rendah lemak',
      'Lainnya',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arahan makan kamu',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Text('Jenis arahan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in types)
              AibsChoiceChip(
                label: type,
                selected: _dietType == type,
                onTap: () => setState(() => _dietType = type),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Bahan yang dihindari',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _ingredientController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Cari bahan',
            suffixIcon: IconButton(
              tooltip: 'Tambah bahan',
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
            ),
          ),
          onSubmitted: (_) => _addIngredient(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final ingredient in _avoidedIngredients)
              InputChip(
                label: Text(ingredient),
                onDeleted: () =>
                    setState(() => _avoidedIngredients.remove(ingredient)),
                backgroundColor: AibsColors.primarySoft,
                side: BorderSide.none,
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Batas porsi', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        AibsCard(
          child: Row(
            children: [
              const Expanded(child: Text('Nasi putih')),
              IconButton(
                tooltip: 'Kurangi porsi',
                onPressed: _ricePortions > 0
                    ? () => setState(() => _ricePortions--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('Maks $_ricePortions porsi'),
              IconButton(
                tooltip: 'Tambah porsi',
                onPressed: () => setState(() => _ricePortions++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTracking(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kita mulai dari mencatat dulu',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        const Center(child: AibsMascot(expression: 'mikir', size: 180)),
        const SizedBox(height: 12),
        Text(
          'Catat makan dan gejala, nanti jadi ringkasan buat konsultasi.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildAllergies(BuildContext context) {
    const choices = [
      'Kacang',
      'Udang',
      'Telur',
      'Susu',
      'Gluten',
      'Ikan',
      'Kedelai',
      'Kerang',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kamu alergi apa?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final choice in choices)
              AibsChoiceChip(
                label: choice,
                selected: _allergies.contains(choice),
                onTap: () => setState(() {
                  if (!_allergies.add(choice)) _allergies.remove(choice);
                }),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _fieldLabel('Alergi lain'),
        TextField(
          controller: _otherAllergyController,
          decoration: const InputDecoration(hintText: 'Cari bahan'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() => _allergies.add(value.trim()));
              _otherAllergyController.clear();
            }
          },
        ),
        if (_allergies.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final item in _allergies)
                InputChip(
                  label: Text(item),
                  onDeleted: () => setState(() => _allergies.remove(item)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPreferences(BuildContext context) {
    const budgets = ['Hemat', 'Sedang', 'Fleksibel'];
    const spices = ['Tidak pedas', 'Sedikit pedas', 'Pedas'];
    const preferences = [
      'Beli',
      'Masak sendiri',
      'Cepat disiapkan',
      'Vegetarian',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget & preferensi',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Text('Budget per makan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final item in budgets)
              AibsChoiceChip(
                label: item,
                selected: _budget == item,
                onTap: () => setState(() => _budget = item),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Level pedas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in spices)
              AibsChoiceChip(
                label: item,
                selected: _spiceLevel == item,
                onTap: () => setState(() => _spiceLevel = item),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Preferensi', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in preferences)
              AibsChoiceChip(
                label: item,
                selected: _preferences.contains(item),
                onTap: () => setState(() {
                  if (!_preferences.add(item)) _preferences.remove(item);
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cek ulang profil',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        AibsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryRow(
                'Nama',
                _nameController.text.trim().isEmpty
                    ? 'Kamu'
                    : _nameController.text.trim(),
              ),
              _summaryRow('Kondisi', _condition ?? 'Belum dipilih'),
              _summaryRow(
                'Arahan',
                _dietType ??
                    (_condition == null ? 'Belum dipilih' : 'Belum ada'),
              ),
              _summaryRow(
                'Alergi',
                _allergies.isEmpty ? 'Tidak ada' : _allergies.join(', '),
              ),
              _summaryRow('Budget', _budget ?? 'Belum dipilih'),
              _summaryRow('Pedas', _spiceLevel ?? 'Belum dipilih'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () => setState(() => _step = _Step.condition),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Ubah pilihan'),
        ),
      ],
    );
  }

  Widget _modeTab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected
              ? AibsColors.primaryStrong
              : AibsColors.inkMuted,
          textStyle: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AibsColors.inkMuted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AibsColors.inkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AibsColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _addIngredient() {
    final ingredient = _ingredientController.text.trim();
    if (ingredient.isEmpty) return;
    setState(() => _avoidedIngredients.add(ingredient));
    _ingredientController.clear();
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AibsColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AibsColors.primary : AibsColors.line,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AibsColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AibsColors.primary : AibsColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
