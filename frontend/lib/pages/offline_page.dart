import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/theme/aibs_tokens.dart';
import '../data/records_repository.dart';
import '../data/app_services.dart';
import '../data/offline_shell.dart';
import '../widgets/record_card_form.dart';
import '../widgets/aibs_widgets.dart';

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key, required this.records});
  final RecordsRepository records;
  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  bool busy = false;
  String? error;
  Future<void> run(Future<void> Function() action) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = AppServices.message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = widget.records.offline!;
    return Scaffold(
      appBar: AppBar(title: const Text('Data offline')),
      body: ListView(
        padding: const EdgeInsets.all(AibsSpace.s20),
        children: [
          const Text(
            'Data kesehatan disimpan di browser/perangkat ini. Jangan aktifkan di perangkat bersama. Logout menghapus data lokal.',
          ),
          SwitchListTile(
            title: const Text('Simpan data di perangkat ini'),
            value: local.enabled,
            onChanged: busy
                ? null
                : (value) => run(() async {
                    if (value) {
                      await local.enable();
                      await widget.records.load();
                      await offlineShell(true);
                    } else {
                      await local.clear();
                      await offlineShell(false);
                    }
                  }),
          ),
          if (error != null) Text(error!),
          if (local.enabled) ...[
            Text(
              'Data terakhir: ${local.data['cached_at'] ?? "belum tersedia"}',
            ),
            const Text(
              'Draft belum tersimpan di akun dan belum menambah streak.',
            ),
            const SizedBox(height: AibsSpace.s16),
            for (final draft in local.drafts)
              ListTile(
                title: Text(
                  'Draft ${(draft['content'] as Map)['foods'] != null ? "makan" : "gejala"}',
                ),
                subtitle: Text(draft['updated_at'].toString()),
                trailing: IconButton(
                  tooltip: 'Hapus draft lokal',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: busy
                      ? null
                      : () =>
                            run(() => local.removeDraft(draft['id'] as String)),
                ),
                onTap: busy
                    ? null
                    : () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocalDraftPage(
                              records: widget.records,
                              draft: draft,
                            ),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
              ),
            const SizedBox(height: AibsSpace.s20),
            Text(
              'Resep tersimpan',
              style: context.aibsText(AibsType.sectionTitle),
            ),
            for (final menu in widget.records.menus.where(
              (m) => m.kind == 'Masak',
            ))
              ExpansionTile(
                title: Text(menu.name),
                children: [
                  CheckboxListTile(
                    title: const Text('Favorit di perangkat'),
                    value: (local.data['favorites'] as List? ?? []).contains(
                      menu.id,
                    ),
                    onChanged: busy
                        ? null
                        : (value) => run(() async {
                            final ids = List<String>.from(
                              local.data['favorites'] as List? ?? [],
                            );
                            ids.remove(menu.id);
                            if (value == true) ids.add(menu.id);
                            local.data['favorites'] = ids;
                            await local.persist();
                          }),
                  ),
                  for (final step in menu.cookSteps)
                    ListTile(title: Text(step)),
                  for (final ingredient in menu.ingredients)
                    ListTile(title: Text(ingredient)),
                  const Text(
                    'Salinan resep. Penilaian perlu dicek ulang saat online.',
                  ),
                ],
              ),
            Text(
              'Checklist offline',
              style: context.aibsText(AibsType.sectionTitle),
            ),
            const Text('Perubahan centang lokal perlu dikirim saat online.'),
            for (final label in widget.records.shoppingLabels)
              CheckboxListTile(
                title: Text(label),
                value: widget.records.checkedShopping.contains(label),
                onChanged: busy
                    ? null
                    : (value) => run(
                        () =>
                            widget.records.checkShopping(label, value == true),
                      ),
              ),
            TextButton(
              onPressed: busy ? null : () => run(widget.records.syncShopping),
              child: const Text('Kirim perubahan checklist'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => run(() async {
                      local.data.remove('shopping_pending');
                      await local.persist();
                      await widget.records.load();
                    }),
              child: const Text('Hapus perubahan checklist lokal'),
            ),
            if (local.drafts.isEmpty)
              const Text(
                'Belum ada draft lokal. Saat mengisi manual atau gejala, tutup lalu pilih Simpan draft.',
              ),
            const SizedBox(height: AibsSpace.s16),
            AibsSecondaryButton(
              label: 'Perbarui data online',
              onPressed: busy ? null : () => run(widget.records.load),
            ),
          ],
        ],
      ),
    );
  }
}

class LocalDraftPage extends StatefulWidget {
  const LocalDraftPage({super.key, required this.records, required this.draft});
  final RecordsRepository records;
  final Map<String, dynamic> draft;
  @override
  State<LocalDraftPage> createState() => _LocalDraftPageState();
}

class _LocalDraftPageState extends State<LocalDraftPage> {
  late final content = Map<String, dynamic>.from(
    jsonDecode(jsonEncode(widget.draft['content'])) as Map,
  );
  bool busy = false;
  String? error;
  Future<void> send() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.records.commitLocal(widget.draft['id'] as String, content);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = AppServices.message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tinjau draft lokal')),
    body: ListView(
      padding: const EdgeInsets.all(AibsSpace.s20),
      children: [
        const Text(
          'Perlu internet untuk kirim. Tinjau waktu dan porsi; ini akan menjadi catatan baru di akun.',
        ),
        for (final card in content['foods'] as List? ?? [])
          RecordCardForm(
            kind: 'food',
            value: card as Map<String, dynamic>,
            ingredientId: widget.records.profiles.ingredientId,
          ),
        for (final card in content['symptoms'] as List? ?? [])
          RecordCardForm(
            kind: 'symptom',
            value: card as Map<String, dynamic>,
            meals: widget.records.meals,
          ),
        if (error != null) Text(error!),
        const SizedBox(height: AibsSpace.s20),
        AibsPrimaryButton(
          label: busy ? 'Mengirim...' : 'Tinjau & kirim',
          onPressed: busy ? null : send,
        ),
        TextButton(
          onPressed: busy
              ? null
              : () async {
                  await widget.records.offline!.draft(
                    widget.draft['id'] as String,
                    content,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
          child: const Text('Simpan draft lokal'),
        ),
      ],
    ),
  );
}
