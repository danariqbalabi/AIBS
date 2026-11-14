import 'package:flutter/material.dart';

import '../core/demo_data.dart';
import '../core/theme/aibs_tokens.dart';
import '../data/records_repository.dart';
import 'aibs_widgets.dart';

class _CardCheckbox extends StatelessWidget {
  const _CardCheckbox({
    required this.title,
    required this.value,
    required this.onChanged,
    this.contentPadding,
  });
  final Widget title;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final EdgeInsetsGeometry? contentPadding;
  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: CheckboxListTile(
      title: title,
      value: value,
      onChanged: onChanged,
      contentPadding: contentPadding,
    ),
  );
}

/// Supplies the server ingredient catalog to forms opened on any route.
class IngredientCatalogScope extends InheritedWidget {
  const IngredientCatalogScope({
    super.key,
    required this.items,
    required super.child,
  });
  final List<Map<String, dynamic>> Function() items;

  static List<Map<String, dynamic>> of(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<IngredientCatalogScope>()
          ?.items() ??
      const [];

  @override
  bool updateShouldNotify(IngredientCatalogScope oldWidget) =>
      oldWidget.items != items;
}

/// Edits a copy of the server card; unknowns and negative observations stay explicit.
class RecordCardForm extends StatefulWidget {
  const RecordCardForm({
    super.key,
    required this.kind,
    required this.value,
    this.ingredientId,
    this.meals = const [],
    this.showConsumptionAndTime = true,
  });
  final String kind;
  final Map<String, dynamic> value;
  final String? Function(String)? ingredientId;
  final List<AibsMealLog> meals;
  final bool showConsumptionAndTime;
  @override
  State<RecordCardForm> createState() => _RecordCardFormState();
}

class _RecordCardFormState extends State<RecordCardForm> {
  Map<String, dynamic> get card => widget.value;
  List<dynamic> get ingredients =>
      card.putIfAbsent('ingredients', () => []) as List;

  /// Bumped when a row name is filled from the catalog so its field redraws.
  final Map<Object, int> _nameRevision = {};

  List<Map<String, dynamic>> get _catalog => IngredientCatalogScope.of(context);

  String? _catalogName(Object? id) {
    if (id == null) return null;
    for (final item in _catalog) {
      if (item['id'] == id) return item['name']?.toString();
    }
    return null;
  }

  String? _resolve(Map row) {
    final name = row['display_name']?.toString().trim() ?? '';
    final byName = name.isEmpty ? null : widget.ingredientId?.call(name);
    return byName ?? row['ingredient_id'] as String?;
  }

  /// A confirmed ingredient must map to a catalog ID, otherwise the server
  /// food check keeps asking for confirmation. When the typed name does not
  /// match, the user picks the matching catalog ingredient instead of the
  /// checkbox silently snapping back.
  Future<void> _toggleConfirmed(Map row, bool? checked) async {
    if (checked != true) {
      setState(
        () => row['certainty'] = row['ingredient_id'] == null
            ? 'unknown'
            : 'candidate',
      );
      return;
    }
    final name = row['display_name']?.toString().trim() ?? '';
    final id = _resolve(row) ?? await _pickIngredient(name);
    if (!mounted) return;
    setState(() {
      if (id == null) {
        row['certainty'] = 'unknown';
        return;
      }
      row['ingredient_id'] = id;
      row['certainty'] = 'confirmed';
      if (name.isEmpty) {
        row['display_name'] = _catalogName(id) ?? '';
        _nameRevision[row] = (_nameRevision[row] ?? 0) + 1;
      }
    });
  }

  Future<String?> _pickIngredient(String name) {
    final catalog = _catalog;
    if (catalog.isEmpty) {
      return showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Katalog bahan belum tersedia'),
          content: const Text(
            'Bahan hanya bisa dikonfirmasi jika cocok dengan katalog. '
            'Muat ulang aplikasi lalu coba lagi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
    var query = '';
    return showDialog<String>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialog) {
          final needle = query.trim().toLowerCase();
          final matches = catalog.where((item) {
            if (needle.isEmpty) return true;
            final names = [item['name'], ...(item['aliases'] as List? ?? [])];
            return names.any(
              (n) => n.toString().toLowerCase().contains(needle),
            );
          }).toList();
          return AlertDialog(
            title: Text(
              name.isEmpty
                  ? 'Pilih bahan dari katalog'
                  : '"$name" belum ada di katalog',
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih bahan katalog yang paling sesuai agar bisa '
                    'dicek dengan profilmu.',
                    style: AibsType.caption,
                  ),
                  const SizedBox(height: AibsSpace.s12),
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Cari bahan',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setDialog(() => query = v),
                  ),
                  const SizedBox(height: AibsSpace.s8),
                  Expanded(
                    child: matches.isEmpty
                        ? const Center(child: Text('Tidak ada bahan cocok.'))
                        : ListView(
                            children: [
                              for (final item in matches)
                                ListTile(
                                  title: Text(item['name'].toString()),
                                  subtitle:
                                      (item['aliases'] as List? ?? []).isEmpty
                                      ? null
                                      : Text(
                                          (item['aliases'] as List).join(', '),
                                        ),
                                  onTap: () =>
                                      Navigator.pop(c, item['id'] as String),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.kind == 'food') ...[
        TextFormField(
          initialValue: card['name'] as String? ?? '',
          decoration: const InputDecoration(labelText: 'Nama makanan'),
          onChanged: (v) => card['name'] = v,
        ),
        if (widget.showConsumptionAndTime)
          _CardCheckbox(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sudah dimakan'),
            value: card['consumed'] == true,
            onChanged: (v) => setState(() => card['consumed'] = v ?? false),
          ),
        Text('Bahan', style: context.aibsText(AibsType.sectionTitle)),
        for (final row in ingredients)
          Padding(
            key: ObjectKey(row),
            padding: const EdgeInsets.only(top: AibsSpace.s12),
            child: AibsCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(_nameRevision[row] ?? 0),
                          initialValue: row['display_name']?.toString() ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Nama bahan',
                          ),
                          // Renaming invalidates a previous confirmation.
                          onChanged: (v) => setState(() {
                            row['display_name'] = v;
                            row['ingredient_id'] = widget.ingredientId?.call(v);
                            row['certainty'] = 'unknown';
                          }),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hapus bahan',
                        onPressed: () =>
                            setState(() => ingredients.remove(row)),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: AibsSpace.s12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: row['quantity']?.toString() ?? '',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Jumlah',
                          ),
                          onChanged: (v) => row['quantity'] = v.trim().isEmpty
                              ? null
                              : v.replaceAll(',', '.'),
                        ),
                      ),
                      const SizedBox(width: AibsSpace.s12),
                      Expanded(
                        child: TextFormField(
                          initialValue: row['unit']?.toString() ?? '',
                          decoration: const InputDecoration(
                            labelText: 'Satuan',
                          ),
                          onChanged: (v) =>
                              row['unit'] = v.trim().isEmpty ? null : v,
                        ),
                      ),
                    ],
                  ),
                  _CardCheckbox(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bahan dikonfirmasi'),
                    value: row['certainty'] == 'confirmed',
                    onChanged: (v) => _toggleConfirmed(row as Map, v),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      row['certainty'] == 'confirmed'
                          ? 'Cocok dengan katalog: '
                                '${_catalogName(row['ingredient_id']) ?? row['display_name']}'
                          : _resolve(row as Map) == null
                          ? 'Belum cocok dengan katalog. Centang untuk memilih '
                                'bahan yang sesuai.'
                          : 'Saran: ${_catalogName(_resolve(row)) ?? 'bahan katalog'}. '
                                'Centang jika sudah benar.',
                      style: AibsType.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () => setState(
            () => ingredients.add(<String, dynamic>{
              'display_name': '',
              'ingredient_id': null,
              'certainty': 'unknown',
            }),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Tambah bahan'),
        ),
        _CardCheckbox(
          contentPadding: EdgeInsets.zero,
          title: const Text('Daftar bahan sudah lengkap'),
          value: card['ingredients_complete'] == true,
          onChanged: (v) =>
              setState(() => card['ingredients_complete'] = v ?? false),
        ),
      ] else ...[
        DropdownButtonFormField<String>(
          initialValue: card['code'] as String? ?? 'other',
          decoration: const InputDecoration(labelText: 'Gejala'),
          items: [
            for (final e in symptomCodes.entries)
              DropdownMenuItem(value: e.value, child: Text(e.key)),
          ],
          onChanged: (v) => setState(() {
            card['code'] = v;
            if (v != 'bowel') card['bristol_type'] = null;
          }),
        ),
        if (card['code'] == 'other')
          Padding(
            padding: const EdgeInsets.only(top: AibsSpace.s12),
            child: TextFormField(
              initialValue: card['label'] as String? ?? '',
              decoration: const InputDecoration(labelText: 'Nama gejala lain'),
              onChanged: (v) =>
                  card['label'] = v.trim().isEmpty ? null : v.trim(),
            ),
          ),
        _CardCheckbox(
          contentPadding: EdgeInsets.zero,
          title: const Text('Gejala dialami'),
          value: card['present'] == true,
          onChanged: (v) => setState(() {
            card['present'] = v ?? false;
            if (v != true) {
              card['severity'] = null;
              card['bristol_type'] = null;
            }
          }),
        ),
        if (card['present'] == true) ...[
          DropdownButtonFormField<int>(
            key: ValueKey('severity-${card['code']}-${card['present']}'),
            initialValue: card['severity'] as int?,
            decoration: const InputDecoration(labelText: 'Seberapa ganggu?'),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('Belum diisi'),
              ),
              for (var i = 1; i <= 5; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) => card['severity'] = v,
          ),
          if (card['code'] == 'bowel')
            DropdownButtonFormField<int>(
              initialValue: card['bristol_type'] as int?,
              decoration: const InputDecoration(labelText: 'Bristol'),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Belum diisi'),
                ),
                for (var i = 1; i <= 7; i++)
                  DropdownMenuItem(value: i, child: Text('$i')),
              ],
              onChanged: (v) => card['bristol_type'] = v,
            ),
        ],
        const SizedBox(height: AibsSpace.s12),
        DropdownButtonFormField<String>(
          initialValue: card['stress'] as String?,
          decoration: const InputDecoration(labelText: 'Stres'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Belum diisi')),
            DropdownMenuItem(value: 'low', child: Text('Rendah')),
            DropdownMenuItem(value: 'medium', child: Text('Sedang')),
            DropdownMenuItem(value: 'high', child: Text('Tinggi')),
          ],
          onChanged: (v) => card['stress'] = v,
        ),
        if (widget.meals.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AibsSpace.s12),
            child: DropdownButtonFormField<String>(
              initialValue:
                  widget.meals.any((m) => m.id == card['linked_food_event_id'])
                  ? card['linked_food_event_id'] as String?
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Hubungkan makanan'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Tidak dihubungkan'),
                ),
                for (final meal in widget.meals.where((m) => m.id != null))
                  DropdownMenuItem(
                    value: meal.id,
                    child: Text(
                      '${meal.name} · ${meal.time}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                card['linked_food_index'] = null;
                card['linked_food_event_id'] = v;
              },
            ),
          ),
      ],
      const SizedBox(height: AibsSpace.s16),
      if (widget.showConsumptionAndTime) CardTimeForm(value: card),
      const SizedBox(height: AibsSpace.s12),
      TextFormField(
        initialValue: card['notes'] as String? ?? '',
        minLines: 1,
        maxLines: 4,
        decoration: const InputDecoration(labelText: 'Catatan'),
        onChanged: (v) => card['notes'] = v.trim().isEmpty ? null : v,
      ),
    ],
  );
}

class CardTimeForm extends StatefulWidget {
  const CardTimeForm({super.key, required this.value});
  final Map<String, dynamic> value;
  @override
  State<CardTimeForm> createState() => _CardTimeFormState();
}

class _CardTimeFormState extends State<CardTimeForm> {
  Map<String, dynamic> get time {
    if (widget.value['time'] is! Map<String, dynamic>) {
      widget.value['time'] = <String, dynamic>{
        'date': dateLabel(DateTime.now()),
        'period': 'midday',
        'precision': 'approximate',
        'confirmed': false,
      };
    }
    return widget.value['time'] as Map<String, dynamic>;
  }

  DateTime get date =>
      DateTime.tryParse(time['date']?.toString() ?? '') ?? DateTime.now();
  DateTime? get exact =>
      DateTime.tryParse(time['occurred_at']?.toString() ?? '')?.toLocal();
  Future<void> _date() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (time['precision'] == 'exact' && exact != null) {
        final updated = eventTime(selected, clockLabel(exact!));
        final confirmed = time['confirmed'];
        time
          ..clear()
          ..addAll(updated)
          ..['confirmed'] = confirmed;
      } else {
        time['date'] = dateLabel(selected);
      }
    });
  }

  Future<void> _clock() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: exact == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(exact!),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final confirmed = time['confirmed'];
      final updated = eventTime(
        date,
        '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}',
      );
      time
        ..clear()
        ..addAll(updated)
        ..['confirmed'] = confirmed;
    });
  }

  @override
  Widget build(BuildContext context) => AibsCard(
    child: Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Tanggal'),
          trailing: TextButton(
            onPressed: _date,
            child: Text(time['date'].toString()),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: time['precision'] as String? ?? 'approximate',
          decoration: const InputDecoration(labelText: 'Ketepatan waktu'),
          items: const [
            DropdownMenuItem(value: 'exact', child: Text('Jam pasti')),
            DropdownMenuItem(value: 'approximate', child: Text('Perkiraan')),
          ],
          onChanged: (v) => setState(() {
            time['precision'] = v;
            time['confirmed'] = false;
            if (v == 'approximate') {
              time['occurred_at'] = null;
              time['period'] = 'midday';
            } else {
              time['period'] = null;
              time['occurred_at'] = null;
            }
          }),
        ),
        if (time['precision'] == 'exact')
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Jam'),
            trailing: TextButton(
              onPressed: _clock,
              child: Text(exact == null ? 'Pilih jam' : clockLabel(exact!)),
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: time['period'] as String? ?? 'midday',
            decoration: const InputDecoration(labelText: 'Perkiraan'),
            items: const [
              DropdownMenuItem(value: 'morning', child: Text('Pagi')),
              DropdownMenuItem(value: 'midday', child: Text('Siang')),
              DropdownMenuItem(value: 'late_afternoon', child: Text('Sore')),
              DropdownMenuItem(value: 'evening', child: Text('Malam')),
              DropdownMenuItem(value: 'night', child: Text('Larut malam')),
            ],
            onChanged: (v) => time['period'] = v,
          ),
        _CardCheckbox(
          contentPadding: EdgeInsets.zero,
          title: const Text('Waktu sudah ditinjau'),
          value: time['confirmed'] == true,
          onChanged: (v) => setState(() => time['confirmed'] = v ?? false),
        ),
      ],
    ),
  );
}
