import 'package:flutter/material.dart';

import 'profile_setup_flow.dart';
import '../shared/widgets/koala.dart';
import '../theme/aibs_theme.dart';
import '../widgets/aibs_widgets.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({required this.onOpenCamera, super.key, this.userName});

  final VoidCallback onOpenCamera;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final name = userName;
    final greetingName = name == null || name.isEmpty ? 'Nadia' : name;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text('Hari Ini', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        AibsCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hai, $greetingName!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mau catat apa hari ini?',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const AibsMascot(expression: 'senang', size: 92),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hari ini', style: Theme.of(context).textTheme.titleLarge),
            Text(
              'Belum ada catatan',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AibsCard(
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AibsColors.primarySoft,
                child: Icon(
                  Icons.restaurant_outlined,
                  color: AibsColors.primaryStrong,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Catatan makan dan gejala muncul di sini'),
              ),
              IconButton(
                tooltip: 'Catat makanan',
                onPressed: onOpenCamera,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AibsColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Cek makanan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        AibsPrimaryButton(
          label: 'Foto makanan',
          icon: Icons.camera_alt_outlined,
          onPressed: onOpenCamera,
        ),
      ],
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.profile, this.onProfileSaved});

  final ProfileSetupAnswers? profile;
  final ValueChanged<ProfileSetupAnswers>? onProfileSaved;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileSetupAnswers? _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) _profile = widget.profile;
  }

  @override
  Widget build(BuildContext context) {
    final profileData = _profile;
    final name = profileData?.displayName;
    final displayName = name == null || name.isEmpty ? 'Nadia' : name;
    final email = profileData?.email;
    final diet = profileData?.dietType;
    final dietPhase = profileData?.dietPhase;
    final dietValue = diet == null
        ? 'Belum diisi'
        : diet == 'Low FODMAP' && dietPhase != null
        ? '$diet · ${dietPhase.toLowerCase()}'
        : diet;
    final avoided = profileData?.avoidedIngredients;
    final allergies = profileData == null
        ? 'Udang'
        : profileData.allergies.isEmpty
        ? 'Nggak ada'
        : profileData.allergies.join(' · ');
    final budgetValue = profileData?.budget;
    final budget = budgetValue == null
        ? 'Maks Rp25.000 per makan'
        : 'Maks $budgetValue per makan';
    final spicyValue = profileData?.spicy;
    final spicy = spicyValue == null
        ? 'Sedikit pedas'
        : switch (spicyValue) {
            'Nggak pedas' => 'Nggak pedas',
            'Sedikit' => 'Sedikit pedas',
            'Sedang' => 'Sedang pedas',
            'Pedas banget' => 'Pedas banget',
            _ => spicyValue,
          };
    final preferences = profileData?.preferences;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text('Profil', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        AibsCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AibsColors.primarySoft,
                child: Icon(
                  Icons.person_outline,
                  color: AibsColors.primaryStrong,
                  size: 30,
                ),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email == null || email.isEmpty ? 'Nama panggilan' : email,
                    style: TextStyle(color: AibsColors.inkMuted, fontSize: 12),
                  ),
                  SizedBox(height: 3),
                  Text(
                    displayName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ProfileSection(
          title: 'Arahan makan',
          value: dietValue,
          detail: avoided == null || avoided.isEmpty
              ? 'Belum ada bahan dihindari'
              : avoided.join(' · '),
          onTap: _openEdit,
        ),
        const SizedBox(height: 12),
        _ProfileSection(
          title: 'Alergi',
          value: allergies,
          detail: 'Bisa kamu ubah kapan saja',
        ),
        const SizedBox(height: 12),
        _ProfileSection(
          title: 'Budget & preferensi',
          value: budget,
          detail: [
            spicy,
            if (preferences != null && preferences.isNotEmpty)
              preferences.join(' · '),
          ].join(' · '),
        ),
      ],
    );
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<ProfileSetupAnswers>(
      MaterialPageRoute(
        builder: (_) => _EditDietPage(profile: _profile ?? _demoProfile),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _profile = updated);
    widget.onProfileSaved?.call(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan tersimpan untuk sesi ini')),
    );
  }

  static ProfileSetupAnswers get _demoProfile => ProfileSetupAnswers(
    displayName: 'Nadia',
    email: '',
    ageBand: null,
    diagnosis: null,
    clinicianGuidance: null,
    redFlags: const [],
    pattern: const [],
    dietType: 'Low FODMAP',
    dietPhase: 'Eliminasi',
    avoidedIngredients: const ['Bawang putih', 'Bawang bombay', 'Susu sapi'],
    portionLimits: const {'Nasi': 1, 'Buah': 1, 'Roti': null},
    allergies: const ['Udang'],
    tolerances: const [],
    budget: 'Rp25.000',
    spicy: 'Sedikit',
    preferences: const [],
  );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.value,
    required this.detail,
    this.onTap,
  });

  final String title;
  final String value;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AibsCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: onTap == null ? EdgeInsets.zero : const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditDietPage extends StatefulWidget {
  const _EditDietPage({required this.profile});

  final ProfileSetupAnswers profile;

  @override
  State<_EditDietPage> createState() => _EditDietPageState();
}

class _EditDietPageState extends State<_EditDietPage> {
  static const _dietTypes = [
    'Low FODMAP',
    'Rendah lemak',
    'Tinggi serat',
    'Belum ada arahan',
    'Lainnya',
  ];
  static const _dietPhases = [
    'Eliminasi',
    'Reintroduksi',
    'Personalisasi',
    'Belum tahu',
  ];

  late String _dietType;
  late String _dietPhase;
  late final Map<String, bool> _avoided;
  late final Map<String, int?> _portionLimits;
  final _customController = TextEditingController();
  final _portionController = TextEditingController();
  String? _ingredientError;
  String? _portionError;

  @override
  void initState() {
    super.initState();
    _dietType = widget.profile.dietType ?? 'Belum ada arahan';
    _dietPhase = widget.profile.dietPhase ?? 'Belum tahu';
    _avoided = {
      for (final ingredient in widget.profile.avoidedIngredients)
        ingredient: true,
    };
    _portionLimits = Map.of(widget.profile.portionLimits);
  }

  @override
  void dispose() {
    _customController.dispose();
    _portionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arahan diet')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Jenis arahan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: _dietType,
                  onChanged: (value) {
                    if (value != null) setState(() => _dietType = value);
                  },
                  child: Column(
                    children: [
                      for (final item in _dietTypes)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item),
                          value: item,
                        ),
                    ],
                  ),
                ),
                if (_dietType == 'Low FODMAP') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Fase Low FODMAP',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final phase in _dietPhases)
                        AibsChoiceChip(
                          label: phase,
                          selected: _dietPhase == phase,
                          onTap: () => setState(() => _dietPhase = phase),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Bahan yang dihindari',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customController,
                  decoration: InputDecoration(
                    hintText: 'Tambah bahan',
                    errorText: _ingredientError,
                    suffixIcon: IconButton(
                      tooltip: 'Tambah bahan',
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                  onChanged: (_) => setState(() => _ingredientError = null),
                  onSubmitted: (_) => _addIngredient(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _avoided.entries)
                      InputChip(
                        label: Text(
                          entry.key,
                          style: TextStyle(
                            decoration: entry.value
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        selected: entry.value,
                        onPressed: () => _toggleAvoided(entry.key),
                        deleteButtonTooltipMessage: entry.value
                            ? 'Hapus ${entry.key}'
                            : 'Pulihkan ${entry.key}',
                        deleteIcon: Icon(
                          entry.value ? Icons.close : Icons.undo,
                        ),
                        onDeleted: () => _toggleAvoided(entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Batas porsi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final item in _portionLimits.keys.toList())
                  _portionRow(item),
                const SizedBox(height: 12),
                TextField(
                  controller: _portionController,
                  decoration: InputDecoration(
                    hintText: 'Tambah batas porsi',
                    errorText: _portionError,
                    suffixIcon: IconButton(
                      tooltip: 'Tambah batas porsi',
                      onPressed: _addPortionLimit,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _portionError = null),
                  onSubmitted: (_) => _addPortionLimit(),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: AibsPrimaryButton(
                  label: 'Simpan perubahan',
                  onPressed: _save,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addIngredient() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    if (_avoided[value] == true) {
      setState(() => _ingredientError = 'Bahan ini sudah ada.');
      return;
    }
    setState(() {
      _avoided[value] = true;
      _ingredientError = null;
    });
    _customController.clear();
  }

  Widget _portionRow(String ingredient) {
    final portion = _portionLimits[ingredient] ?? 0;
    return AibsCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              ingredient,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Kurangi porsi $ingredient',
            onPressed: () => _changePortion(ingredient, -1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            portion == 0 ? 'Tidak ada' : '$portion porsi',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            tooltip: 'Tambah porsi $ingredient',
            onPressed: () => _changePortion(ingredient, 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  void _changePortion(String ingredient, int delta) {
    setState(() {
      final current = _portionLimits[ingredient] ?? 0;
      _portionLimits[ingredient] = (current + delta).clamp(0, 10).toInt();
    });
  }

  void _addPortionLimit() {
    final ingredient = _portionController.text.trim();
    if (ingredient.isEmpty) return;
    if (_portionLimits.containsKey(ingredient)) {
      setState(() => _portionError = 'Batas porsi ini sudah ada.');
      return;
    }
    setState(() {
      _portionLimits[ingredient] = 0;
      _portionError = null;
    });
    _portionController.clear();
  }

  void _toggleAvoided(String ingredient) {
    setState(() => _avoided[ingredient] = !(_avoided[ingredient] ?? false));
  }

  List<String> get _sensitiveChanges {
    final initialAvoided = widget.profile.avoidedIngredients.toSet();
    final currentAvoided = _avoided.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
    final changes = [
      for (final ingredient in initialAvoided.difference(currentAvoided))
        'Hapus $ingredient dari daftar hindari',
    ];
    for (final entry in widget.profile.portionLimits.entries) {
      final previous = entry.value ?? 0;
      final current = _portionLimits[entry.key] ?? 0;
      if (previous > 0 && current < previous) {
        changes.add('Longgarkan batas porsi ${entry.key.toLowerCase()}');
      }
    }
    return changes;
  }

  Future<void> _save() async {
    final changes = _sensitiveChanges;
    if (changes.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _ConfirmProfileDialog(changes: changes),
      );
      if (confirmed != true || !mounted) return;
    }

    final profile = widget.profile.copyWithDietProfile(
      dietType: _dietType,
      dietPhase: _dietType == 'Low FODMAP' ? _dietPhase : null,
      avoidedIngredients: _avoided.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
      portionLimits: _portionLimits,
    );
    if (mounted) Navigator.of(context).pop(profile);
  }
}

class _ConfirmProfileDialog extends StatelessWidget {
  const _ConfirmProfileDialog({required this.changes});

  final List<String> changes;

  @override
  Widget build(BuildContext context) {
    final title = changes.length == 1
        ? '${changes.single}?'
        : 'Ada perubahan yang melonggarkan batas diet?';
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Koala(KoalaMood.mikir, size: 110),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (changes.length > 1) ...[
            for (final change in changes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(change, textAlign: TextAlign.center),
              ),
            const SizedBox(height: 8),
          ],
          const Text(
            'Pastikan sesuai arahan dokter atau ahli gizimu.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Ya, ubah'),
        ),
      ],
    );
  }
}
