import 'package:flutter/services.dart';

import 'dart:async';

import '../data/app_services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/demo_data.dart';
import '../core/theme/aibs_tokens.dart';
import '../shared/widgets/status_badge.dart';
import '../widgets/aibs_widgets.dart';
import 'profile_setup_flow.dart';
import '../widgets/record_card_form.dart';
import '../data/records_repository.dart';

import 'dart:convert';

class MenuHomePage extends StatefulWidget {
  const MenuHomePage({
    required this.profile,
    required this.shoppingItems,
    required this.onShoppingChanged,
    required this.onStartMealRecord,
    required this.onPlanSaved,
    this.menus,
    this.onAddMenuShopping,
    this.onShoppingChecked,
    this.checkedShopping = const {},
    this.onCheckMenu,
    this.ingredientId,
    this.onShoppingQuantity,
    super.key,
  });

  final ProfileSetupAnswers? profile;
  final List<String> shoppingItems;
  final FutureOr<void> Function(List<String>) onShoppingChanged;
  final List<AibsMenuItem>? menus;
  final FutureOr<void> Function(AibsMenuItem)? onAddMenuShopping;
  final FutureOr<void> Function(String, bool)? onShoppingChecked;
  final Set<String> checkedShopping;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)?
  onCheckMenu;
  final String? Function(String)? ingredientId;
  final Future<void> Function(String, num)? onShoppingQuantity;
  final ValueChanged<AibsMenuItem> onStartMealRecord;
  final FutureOr<void> Function(AibsMealPlan) onPlanSaved;

  @override
  State<MenuHomePage> createState() => _MenuHomePageState();
}

class _MenuHomePageState extends State<MenuHomePage> {
  final _searchController = TextEditingController();
  String _kind = 'Semua';
  bool _withinBudget = true;
  bool _quickOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final budget = _budget;
    final filtered = (widget.menus ?? aibsDemoMenus).where((item) {
      final matchesText = item.name.toLowerCase().contains(
        _searchController.text.trim().toLowerCase(),
      );
      final matchesKind = _kind == 'Semua' || item.kind == _kind;
      final matchesBudget = !_withinBudget || item.price <= budget;
      final matchesTime =
          !_quickOnly ||
          (item.preparationMinutes != null && item.preparationMinutes! <= 15);
      return matchesText && matchesKind && matchesBudget && matchesTime;
    }).toList();

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
            Expanded(child: Text('Menu', style: AibsType.title)),
            _CartButton(
              count: widget.shoppingItems.length,
              onTap: _openShoppingList,
            ),
          ],
        ),
        const SizedBox(height: AibsSpace.s16),
        Text('Katalog demo · harga perkiraan', style: AibsType.micro),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Cari menu',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AibsSpace.s12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in ['Semua', 'Beli', 'Masak']) ...[
                _FilterChip(
                  label: option,
                  selected: _kind == option,
                  onTap: () => setState(() => _kind = option),
                ),
                const SizedBox(width: AibsSpace.s8),
              ],
              _FilterChip(
                label: '≤ ${formatRupiah(budget)}',
                selected: _withinBudget,
                onTap: () => setState(() => _withinBudget = !_withinBudget),
              ),
              const SizedBox(width: AibsSpace.s8),
              _FilterChip(
                label: '≤ 15 menit',
                selected: _quickOnly,
                onTap: () => setState(() => _quickOnly = !_quickOnly),
              ),
            ],
          ),
        ),
        const SizedBox(height: AibsSpace.s20),
        for (final status in CheckStatus.values)
          if (filtered.any((item) => item.status == status)) ...[
            StatusGroupHeader(status),
            const SizedBox(height: AibsSpace.s10),
            for (final item in filtered.where((item) => item.status == status))
              Padding(
                padding: const EdgeInsets.only(bottom: AibsSpace.s10),
                child: _MenuCard(item: item, onTap: () => _openDetail(item)),
              ),
            const SizedBox(height: AibsSpace.s12),
          ],
        if (filtered.isEmpty)
          const AibsCard(child: Text('Menu belum ditemukan.')),
      ],
    );
  }

  int get _budget {
    final value = widget.profile?.budget;
    final digits = value?.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits ?? '') ?? 25000;
  }

  void _openDetail(AibsMenuItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MenuDetailPage(
          onCheckMenu: widget.onCheckMenu,
          ingredientId: widget.ingredientId,
          item: item,
          onAddShopping: _addIngredientsToShoppingList,
          onStartMealRecord: widget.onStartMealRecord,
          onPlanSaved: widget.onPlanSaved,
        ),
      ),
    );
  }

  Future<void> _addIngredientsToShoppingList(AibsMenuItem item) async {
    if (widget.onAddMenuShopping != null) {
      await widget.onAddMenuShopping!(item);
      return;
    }
    final next = {...widget.shoppingItems, ...item.ingredients}.toList();
    await widget.onShoppingChanged(next);
  }

  void _openShoppingList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShoppingListPage(
          onQuantity: widget.onShoppingQuantity,
          items: widget.shoppingItems,
          initialChecked: widget.checkedShopping,
          onChecked: widget.onShoppingChecked,
          onChanged: widget.onShoppingChanged,
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Checklist belanja${count == 0 ? '' : ', $count bahan'}',
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: SvgPicture.asset(
          'assets/icons/cart.svg',
          width: AibsSize.navIcon,
          height: AibsSize.navIcon,
          colorFilter: const ColorFilter.mode(AibsColors.ink, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      color: selected ? AibsColors.primarySoft : AibsColors.card,
      borderRadius: BorderRadius.circular(AibsRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AibsRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: AibsSize.filterChip),
          padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AibsRadius.pill),
            border: Border.all(
              color: selected ? AibsColors.primarySoft : AibsColors.line,
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: AibsType.small.copyWith(
              color: selected ? AibsColors.primaryStrong : AibsColors.ink,
              fontWeight: AibsType.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item, required this.onTap});
  final AibsMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AibsColors.card,
      borderRadius: BorderRadius.circular(AibsRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AibsRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AibsSpace.s10),
          child: Row(
            children: [
              Container(
                width: AibsSize.thumb,
                height: AibsSize.thumb,
                decoration: BoxDecoration(
                  gradient: AibsGradients.food(AibsColors.foodBlue),
                  borderRadius: BorderRadius.circular(AibsRadius.md),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/illustrations/bowl.svg',
                    width: 42,
                    height: 42,
                  ),
                ),
              ),
              const SizedBox(width: AibsSpace.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AibsType.bodyStrong),
                    const SizedBox(height: AibsSpace.s4),
                    Text(item.meta, style: AibsType.small),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuDetailPage extends StatefulWidget {
  const MenuDetailPage({
    super.key,
    required this.item,
    required this.onAddShopping,
    required this.onStartMealRecord,
    required this.onPlanSaved,
    this.onCheckMenu,
    this.ingredientId,
  });

  final AibsMenuItem item;
  final FutureOr<void> Function(AibsMenuItem) onAddShopping;
  final ValueChanged<AibsMenuItem> onStartMealRecord;
  final FutureOr<void> Function(AibsMealPlan) onPlanSaved;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)?
  onCheckMenu;
  final String? Function(String)? ingredientId;

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  late AibsMenuItem item = widget.item;
  Future<void> _edit() async {
    final card = <String, dynamic>{
      'name': item.name,
      'ingredients': jsonDecode(jsonEncode(item.serverIngredients)),
      'ingredients_complete': item.ingredientsComplete,
    };
    final updated = await Navigator.of(context).push<AibsMenuItem>(
      MaterialPageRoute(
        builder: (_) => _MenuEditPage(
          item: item,
          card: card,
          ingredientId: widget.ingredientId,
          check: widget.onCheckMenu!,
        ),
      ),
    );
    if (updated != null && mounted) setState(() => item = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: AibsSize.menuHero,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AibsGradients.food(AibsColors.foodBlue),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/illustrations/bowl.svg',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + AibsSpace.s8,
                left: AibsSpace.s20,
                child: _BackButton(onTap: () => Navigator.pop(context)),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AibsSpace.s20,
                AibsSpace.s20,
                AibsSpace.s20,
                AibsSpace.s24,
              ),
              children: [
                Text(item.name, style: AibsType.titleDetail),
                const SizedBox(height: AibsSpace.s8),
                Text(
                  '${item.kind} · ${item.priceLabel} · 1 porsi',
                  style: AibsType.caption.copyWith(color: AibsColors.inkMuted),
                ),
                const SizedBox(height: AibsSpace.s10),
                StatusBadge(item.status),
                const SizedBox(height: AibsSpace.s16),
                Container(
                  padding: const EdgeInsets.all(AibsSpace.s12),
                  decoration: BoxDecoration(
                    color: item.status.soft,
                    borderRadius: BorderRadius.circular(AibsRadius.lg),
                  ),
                  child: Text(
                    item.reason,
                    style: AibsType.caption.copyWith(color: item.status.ink),
                  ),
                ),
                const SizedBox(height: AibsSpace.s20),
                Text(
                  item.kind == 'Beli' ? 'Cara pesan' : 'Cara masak',
                  style: AibsType.sectionTitle,
                ),
                const SizedBox(height: AibsSpace.s8),
                AibsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (index, line)
                          in (item.kind == 'Beli'
                                  ? item.orderTips
                                  : item.cookSteps)
                              .indexed) ...[
                        if (index > 0) const Divider(height: AibsSpace.s20),
                        Text(
                          item.kind == 'Beli' ? line : '${index + 1}. $line',
                          style: AibsType.bodyStrong,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AibsSpace.s20),
                if (item.kind == 'Beli')
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: item.orderTips.join('\n')),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cara pesan disalin')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Salin cara pesan'),
                  ),
                Text('Bahan', style: AibsType.sectionTitle),
                if (widget.onCheckMenu != null)
                  TextButton(
                    onPressed: _edit,
                    child: const Text('Ubah porsi / ganti bahan'),
                  ),
                const SizedBox(height: AibsSpace.s8),
                AibsCard(
                  child: Column(
                    children: [
                      for (final (index, ingredient)
                          in item.ingredients.indexed) ...[
                        if (index > 0) const Divider(height: AibsSpace.s16),
                        _IngredientLine(
                          ingredient: ingredient,
                          status: item.status,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AibsSpace.s12),
                if (item.kind == 'Masak')
                  AibsSecondaryButton(
                    label: 'Masukkan ke checklist belanja',
                    onPressed: () async {
                      try {
                        await widget.onAddShopping(item);
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppServices.message(error))),
                          );
                        }
                        return;
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bahan ditambahkan')),
                      );
                    },
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AibsSpace.s20,
                AibsSpace.s12,
                AibsSpace.s20,
                AibsSpace.s16,
              ),
              decoration: const BoxDecoration(
                color: AibsColors.card,
                boxShadow: AibsShadows.bar,
                borderRadius: AibsRadius.sheetTop,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AibsSecondaryButton(
                      label: 'Jadwalkan',
                      onPressed: () => _schedule(context),
                    ),
                  ),
                  const SizedBox(width: AibsSpace.s10),
                  Expanded(
                    child: AibsPrimaryButton(
                      label: 'Sudah dimakan',
                      onPressed: () => widget.onStartMealRecord(item),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _schedule(BuildContext context) async {
    await showModalBottomSheet<AibsMealPlan>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ScheduleSheet(menu: item, onSave: widget.onPlanSaved),
    );
  }
}

class _MenuEditPage extends StatefulWidget {
  const _MenuEditPage({
    required this.item,
    required this.card,
    required this.check,
    this.ingredientId,
  });
  final AibsMenuItem item;
  final Map<String, dynamic> card;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) check;
  final String? Function(String)? ingredientId;
  @override
  State<_MenuEditPage> createState() => _MenuEditPageState();
}

class _MenuEditPageState extends State<_MenuEditPage> {
  bool _busy = false;
  String? _error;
  Future<void> _check() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.check(widget.card);
      final previous = widget.item;
      final rows = (widget.card['ingredients'] as List)
          .cast<Map<String, dynamic>>();
      final updated = AibsMenuItem(
        id: previous.id,
        name: widget.card['name'] as String,
        kind: previous.kind,
        price: previous.price,
        status: statusFor(result['status']),
        reason: [
          for (final r in result['reasons'] as List? ?? [])
            r['message'].toString(),
          ...(result['missing_information'] as List? ?? []).cast<String>(),
        ].join('\n'),
        ingredients: rows.map(RecordsRepository.ingredientLabel).toList(),
        serverIngredients: rows,
        orderTips: previous.orderTips,
        cookSteps: previous.cookSteps,
        customized: true,
        ingredientsComplete: widget.card['ingredients_complete'] == true,
        preparationMinutes: previous.preparationMinutes,
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (error) {
      if (mounted) setState(() => _error = AppServices.message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ubah bahan & porsi')),
    body: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AibsSpace.s20),
            child: AbsorbPointer(
              absorbing: _busy,
              child: RecordCardForm(
                kind: 'food',
                value: widget.card,
                ingredientId: widget.ingredientId,
                showConsumptionAndTime: false,
              ),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(AibsSpace.s12),
            child: Text(_error!),
          ),
        SafeArea(
          child: Padding(
            padding: AibsSpace.bottomActions,
            child: AibsPrimaryButton(
              label: _busy ? 'Mengecek...' : 'Cek ulang & gunakan',
              onPressed: _busy ? null : _check,
            ),
          ),
        ),
      ],
    ),
  );
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AibsColors.card,
      borderRadius: BorderRadius.circular(AibsRadius.sm),
      child: IconButton(
        tooltip: 'Kembali',
        onPressed: onTap,
        icon: const Icon(Icons.arrow_back, size: 22),
      ),
    );
  }
}

class _IngredientLine extends StatelessWidget {
  const _IngredientLine({required this.ingredient, required this.status});
  final String ingredient;
  final CheckStatus status;

  @override
  Widget build(BuildContext context) {
    final result = status;
    return Row(
      children: [
        StatusDot(result),
        const SizedBox(width: AibsSpace.s10),
        Expanded(child: Text(ingredient, style: AibsType.bodyStrong)),
      ],
    );
  }
}

class _ScheduleSheet extends StatefulWidget {
  const _ScheduleSheet({required this.menu, required this.onSave});
  final AibsMenuItem menu;
  final FutureOr<void> Function(AibsMealPlan) onSave;

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  String _day = 'Hari ini';
  bool _saving = false;
  String _meal = 'Malam';
  static const _weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  final _anchor = DateTime.now();
  late final _days = [
    'Hari ini',
    'Besok',
    for (final offset in [2, 3])
      _weekdays[_anchor.add(Duration(days: offset)).weekday - 1],
  ];
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
              Text('Jadwalkan', style: AibsType.sheetTitle),
              const SizedBox(height: AibsSpace.s16),
              Text('Hari', style: AibsType.caption),
              const SizedBox(height: AibsSpace.s8),
              Wrap(
                spacing: AibsSpace.s8,
                children: [
                  for (final day in _days)
                    _FilterChip(
                      label: day,
                      selected: _day == day,
                      onTap: () => setState(() => _day = day),
                    ),
                ],
              ),
              const SizedBox(height: AibsSpace.s16),
              Text('Waktu', style: AibsType.caption),
              const SizedBox(height: AibsSpace.s8),
              Wrap(
                spacing: AibsSpace.s8,
                children: [
                  for (final meal in ['Pagi', 'Siang', 'Malam', 'Camilan'])
                    _FilterChip(
                      label: meal,
                      selected: _meal == meal,
                      onTap: () => setState(() => _meal = meal),
                    ),
                ],
              ),
              const SizedBox(height: AibsSpace.s12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jam'),
                trailing: TextButton(
                  onPressed: _pickTime,
                  child: Text(
                    '${_time.hour.toString().padLeft(2, '0')}.${_time.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              AibsPrimaryButton(
                label: 'Simpan rencana',
                onPressed: () async {
                  if (_saving) return;
                  _saving = true;
                  final plan = AibsMealPlan(
                    menu: widget.menu,
                    day: _day,
                    meal: _meal,
                    time:
                        '${_time.hour.toString().padLeft(2, '0')}.${_time.minute.toString().padLeft(2, '0')}',
                    scheduledAt: DateTime(
                      _anchor.year,
                      _anchor.month,
                      _anchor.day + _days.indexOf(_day),
                      _time.hour,
                      _time.minute,
                    ),
                  );
                  try {
                    await widget.onSave(plan);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppServices.message(error))),
                      );
                    }
                    _saving = false;
                    return;
                  }
                  _saving = false;
                  if (context.mounted &&
                      ModalRoute.of(context)?.isCurrent == true) {
                    Navigator.pop(context, plan);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) setState(() => _time = selected);
  }
}

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialChecked = const {},
    this.onChecked,
    this.onQuantity,
  });
  final List<String> items;
  final Set<String> initialChecked;
  final FutureOr<void> Function(String, bool)? onChecked;
  final Future<void> Function(String, num)? onQuantity;
  final FutureOr<void> Function(List<String>) onChanged;

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  late List<String> _items;
  final Set<String> _checked = {};
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
    _checked.addAll(widget.initialChecked);
  }

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
        padding: const EdgeInsets.all(AibsSpace.s20),
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
          const SizedBox(height: AibsSpace.s12),
          if (_items.isEmpty)
            const AibsCard(child: Text('Belum ada bahan di checklist.')),
          for (final item in _items)
            Dismissible(
              key: ValueKey(item),
              direction: DismissDirection.endToStart,
              background: const ColoredBox(
                color: AibsColors.bad,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: AibsSpace.s20),
                    child: Icon(
                      Icons.delete_outline,
                      color: AibsColors.onPrimary,
                    ),
                  ),
                ),
              ),
              confirmDismiss: (_) async {
                try {
                  await widget.onChanged(
                    _items.where((value) => value != item).toList(),
                  );
                  return true;
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppServices.message(error))),
                    );
                  }
                  return false;
                }
              },
              onDismissed: (_) => _remove(item),
              child: CheckboxListTile(
                value: _checked.contains(item),
                onChanged: (value) async {
                  try {
                    await widget.onChecked?.call(item, value ?? false);
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppServices.message(error))),
                      );
                    }
                    return;
                  }
                  if (!mounted) return;
                  setState(() {
                    if (value == true) {
                      _checked.add(item);
                    } else {
                      _checked.remove(item);
                    }
                  });
                },
                title: Text(
                  item,
                  style: AibsType.bodyStrong.copyWith(
                    color: _checked.contains(item)
                        ? AibsColors.inkMuted
                        : AibsColors.ink,
                    decoration: _checked.contains(item)
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: widget.onQuantity == null
                    ? null
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => _editQuantity(item),
                          child: const Text('Ubah jumlah'),
                        ),
                      ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _editQuantity(String item) async {
    final controller = TextEditingController(
      text: RegExp(r'·\s*([0-9.,]+)').firstMatch(item)?[1] ?? '1',
    );
    final amount = await showDialog<num>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Ubah jumlah'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Jumlah'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final n = num.tryParse(controller.text.replaceAll(',', '.'));
              if (n != null && n > 0 && n <= 10000) Navigator.pop(c, n);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null) return;
    try {
      await widget.onQuantity!(item, amount);
      if (!mounted) return;
      final display = amount == amount.toInt()
          ? amount.toInt().toString()
          : amount.toString();
      final updated = item.replaceFirst(RegExp(r'·\s*[0-9.,]+'), '· $display');
      setState(() {
        _items[_items.indexOf(item)] = updated;
        if (_checked.remove(item)) _checked.add(updated);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppServices.message(error))));
      }
    }
  }

  Future<void> _add() async {
    final raw = _controller.text.trim();
    final value =
        widget.onChecked != null && !raw.contains('·') && raw.isNotEmpty
        ? '$raw · 1 porsi'
        : raw;
    if (value.isEmpty || _items.contains(value)) return;
    final next = [..._items, value];
    try {
      await widget.onChanged(next);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppServices.message(error))));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _items = next);
    _controller.clear();
  }

  void _remove(String value) {
    final next = _items.where((item) => item != value).toList();
    setState(() {
      _items = next;
      _checked.remove(value);
    });
  }
}
