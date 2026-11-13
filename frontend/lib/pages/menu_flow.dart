import 'package:flutter/material.dart';

import '../shared/widgets/status_badge.dart';
import '../theme/aibs_theme.dart';
import '../widgets/aibs_widgets.dart';

CheckStatus _statusFromLabel(String status) => switch (status) {
  'Sesuai' => CheckStatus.ok,
  'Hati-hati' => CheckStatus.warn,
  'Tidak sesuai' => CheckStatus.bad,
  _ => CheckStatus.unknown,
};

class MenuHomePage extends StatefulWidget {
  const MenuHomePage({super.key});

  @override
  State<MenuHomePage> createState() => _MenuHomePageState();
}

class _MenuHomePageState extends State<MenuHomePage> {
  final _searchController = TextEditingController();
  String _filter = 'Semua';

  static const _menu = [
    _MenuItem(
      'Nasi ayam bakar kecap',
      'Beli · Rp22.000 · tanpa bawang',
      'Sesuai',
      Icons.rice_bowl_outlined,
    ),
    _MenuItem(
      'Tumis tahu wortel',
      'Masak · Rp15.000 · tanpa bawang',
      'Sesuai',
      Icons.soup_kitchen_outlined,
    ),
    _MenuItem(
      'Nasi goreng telur',
      'Beli · Rp18.000 · nasi 1½ porsi',
      'Hati-hati',
      Icons.rice_bowl_outlined,
    ),
    _MenuItem(
      'Soto ayam santan',
      'Beli · Rp20.000 · ada bawang putih',
      'Tidak sesuai',
      Icons.soup_kitchen_outlined,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _menu.where((item) {
      final matchesText = item.name.toLowerCase().contains(
        _searchController.text.toLowerCase(),
      );
      final matchesFilter =
          _filter == 'Semua' ||
          (_filter == 'Beli' && item.description.startsWith('Beli')) ||
          (_filter == 'Masak' && item.description.startsWith('Masak')) ||
          (_filter == '≤ Rp25.000' && item.description.contains('Rp'));
      return matchesText && matchesFilter;
    }).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: 'Checklist belanja',
              onPressed: () => _open(context, const _ShoppingListPage()),
              icon: const Icon(Icons.checklist_outlined),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Cari menu',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final option in ['Semua', 'Beli', 'Masak', '≤ Rp25.000'])
              AibsChoiceChip(
                label: option,
                selected: _filter == option,
                onTap: () => setState(() => _filter = option),
              ),
          ],
        ),
        const SizedBox(height: 24),
        for (final status in ['Sesuai', 'Hati-hati', 'Tidak sesuai']) ...[
          StatusGroupHeader(_statusFromLabel(status)),
          const SizedBox(height: 10),
          for (final item in filtered.where((item) => item.status == status))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MenuCard(
                item: item,
                onTap: () => _open(context, _MenuDetailPage(item: item)),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _MenuItem {
  const _MenuItem(this.name, this.description, this.status, this.icon);

  final String name;
  final String description;
  final String status;
  final IconData icon;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item, required this.onTap});

  final _MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AibsCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AibsColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: AibsColors.primaryStrong),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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

class _MenuDetailPage extends StatelessWidget {
  const _MenuDetailPage({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final ingredients = [
      'Nasi putih · 1 porsi',
      'Ayam paha · 100 g',
      'Kecap manis · 1 sdm',
      'Jahe · 1 ruas',
      'Timun · 3 iris',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Detail menu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
              color: AibsColors.primarySoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.rice_bowl_outlined,
              size: 64,
              color: AibsColors.primaryStrong,
            ),
          ),
          const SizedBox(height: 20),
          Text(item.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          StatusBadge(_statusFromLabel(item.status)),
          const SizedBox(height: 24),
          Text('Bahan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final ingredient in ingredients)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.check_circle_outline,
                color: AibsColors.ok,
              ),
              title: Text(ingredient),
            ),
          const SizedBox(height: 16),
          AibsSecondaryButton(
            label: 'Masukkan ke checklist belanja',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const _ShoppingListPage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AibsPrimaryButton(
            label: 'Saya makan ini',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _ConfirmIngredientsPage(item: item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmIngredientsPage extends StatelessWidget {
  const _ConfirmIngredientsPage({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi bahan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Yang kamu makan sama persis?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          AibsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const Text(
                  'Nasi 1 porsi · Ayam paha 100 g · Kecap manis · Jahe · Timun',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AibsPrimaryButton(
            label: 'Sama persis',
            onPressed: () => _showResult(context, item),
          ),
          const SizedBox(height: 10),
          AibsSecondaryButton(
            label: 'Ada yang beda',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _EditIngredientsPage(item: item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditIngredientsPage extends StatefulWidget {
  const _EditIngredientsPage({required this.item});

  final _MenuItem item;

  @override
  State<_EditIngredientsPage> createState() => _EditIngredientsPageState();
}

class _EditIngredientsPageState extends State<_EditIngredientsPage> {
  final _ingredients = <String>[
    'Nasi putih',
    'Ayam paha',
    'Kecap manis',
    'Jahe',
    'Timun',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah bahan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Sesuaikan bahan yang kamu makan',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          for (final ingredient in _ingredients)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(ingredient),
              trailing: IconButton(
                tooltip: 'Hapus $ingredient',
                onPressed: () =>
                    setState(() => _ingredients.remove(ingredient)),
                icon: const Icon(Icons.close),
              ),
            ),
          AibsPrimaryButton(
            label: 'Cek makanan',
            onPressed: () => _showResult(context, widget.item),
          ),
        ],
      ),
    );
  }
}

class _ShoppingListPage extends StatefulWidget {
  const _ShoppingListPage();

  @override
  State<_ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<_ShoppingListPage> {
  final _items = <String, bool>{
    'Ayam paha · 200 g · 2 resep': false,
    'Kecap manis · 2 sdm': false,
    'Jahe · 2 ruas · 2 resep': false,
    'Tahu putih · 2 potong': false,
    'Wortel · 1 buah': true,
  };
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checklist belanja')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Tambah bahan',
              suffixIcon: IconButton(
                tooltip: 'Tambah',
                onPressed: _add,
                icon: const Icon(Icons.add),
              ),
            ),
            onSubmitted: (_) => _add(),
          ),
          const SizedBox(height: 12),
          for (final item in _items.keys.toList())
            CheckboxListTile(
              value: _items[item],
              onChanged: (value) =>
                  setState(() => _items[item] = value ?? false),
              title: Text(item),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() => _items['$value · 1 porsi'] = false);
    _controller.clear();
  }
}

class _MenuStatus extends StatelessWidget {
  const _MenuStatus({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final checkStatus = switch (status) {
      'Sesuai' => CheckStatus.ok,
      'Hati-hati' => CheckStatus.warn,
      'Tidak sesuai' => CheckStatus.bad,
      _ => throw ArgumentError.value(status, 'status'),
    };
    return StatusBadge(checkStatus);
  }
}

void _showResult(BuildContext context, _MenuItem item) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Hasil cek')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(item.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _MenuStatus(status: item.status),
            const SizedBox(height: 12),
            const Text(
              'Belum tentu penyebab gejala. Hasil ini mengikuti arahan yang kamu simpan.',
            ),
            const SizedBox(height: 24),
            AibsPrimaryButton(
              label: 'Simpan catatan',
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
