import 'package:flutter/material.dart';

import '../theme/aibs_theme.dart';
import '../widgets/aibs_widgets.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({required this.onOpenCamera, super.key});

  final VoidCallback onOpenCamera;

  @override
  Widget build(BuildContext context) {
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
                      'Hai, Nadia!',
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

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text('Profil', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        const AibsCard(
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
                    'Nama panggilan',
                    style: TextStyle(color: AibsColors.inkMuted, fontSize: 12),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Nadia',
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
          value: 'Low FODMAP · eliminasi',
          detail: 'Bawang putih · Bawang bombay · Susu sapi',
          onTap: () => _openEdit(context),
        ),
        const SizedBox(height: 12),
        _ProfileSection(
          title: 'Alergi',
          value: 'Udang',
          detail: 'Bisa kamu ubah kapan saja',
          onTap: () => _openEdit(context),
        ),
        const SizedBox(height: 12),
        _ProfileSection(
          title: 'Budget & preferensi',
          value: 'Maks Rp25.000 per makan',
          detail: 'Sedikit pedas',
          onTap: () => _openEdit(context),
        ),
      ],
    );
  }

  void _openEdit(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const _EditDietPage()));
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.value,
    required this.detail,
    required this.onTap,
  });

  final String title;
  final String value;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AibsCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
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
            const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _EditDietPage extends StatefulWidget {
  const _EditDietPage();

  @override
  State<_EditDietPage> createState() => _EditDietPageState();
}

class _EditDietPageState extends State<_EditDietPage> {
  String _diet = 'Low FODMAP · eliminasi';
  final _avoided = <String>{'Bawang putih', 'Bawang bombay', 'Susu sapi'};
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dietTypes = [
      'Low FODMAP · eliminasi',
      'Low FODMAP · reintroduksi',
      'Rendah lemak',
      'Lainnya',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah arahan diet')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Jenis arahan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in dietTypes)
                AibsChoiceChip(
                  label: item,
                  selected: _diet == item,
                  onTap: () => setState(() => _diet = item),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Bahan yang dihindari',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customController,
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
              for (final item in _avoided)
                InputChip(
                  label: Text(item),
                  onDeleted: () => setState(() => _avoided.remove(item)),
                ),
            ],
          ),
          const SizedBox(height: 28),
          AibsPrimaryButton(
            label: 'Lanjut',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _ConfirmProfilePage(
                  diet: _diet,
                  avoided: _avoided.toList(),
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
    setState(() => _avoided.add(value));
    _customController.clear();
  }
}

class _ConfirmProfilePage extends StatelessWidget {
  const _ConfirmProfilePage({required this.diet, required this.avoided});

  final String diet;
  final List<String> avoided;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi perubahan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Simpan perubahan profil?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          AibsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arahan makan',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(diet, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(
                  'Dihindari',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(avoided.isEmpty ? 'Belum ada' : avoided.join(' · ')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AibsPrimaryButton(
            label: 'Simpan perubahan',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Perubahan tersimpan untuk sesi ini'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
