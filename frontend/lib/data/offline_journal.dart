import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One opt-in document per authenticated subject; never stores access tokens or photos.
class OfflineJournal {
  OfflineJournal(
    this.owner, {
    Future<String?> Function(String)? read,
    Future<void> Function(String, String)? write,
    Future<void> Function(String)? remove,
  }) : _read = read ?? SharedPreferencesAsync().getString,
       _write = write ?? SharedPreferencesAsync().setString,
       _remove = remove ?? SharedPreferencesAsync().remove;
  final String owner;
  final Future<String?> Function(String) _read;
  final Future<void> Function(String, String) _write;
  final Future<void> Function(String) _remove;
  String get key => 'aibs.offline.v1.$owner';
  Map<String, dynamic> data = {};
  bool get enabled => data['enabled'] == true;
  List<Map<String, dynamic>> get drafts =>
      (data['drafts'] as List? ?? []).cast<Map<String, dynamic>>();
  Future<void> load() async {
    final raw = await _read(key);
    data = raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> persist() async {
    if (enabled) await _write(key, jsonEncode(data));
  }

  Future<void> enable() async {
    data['enabled'] = true;
    await persist();
  }

  Future<void> clear() async {
    await _remove(key);
    data = {};
  }

  Future<void> draft(String id, Map<String, dynamic> content) async {
    if (!enabled) {
      throw StateError('Aktifkan simpan data di perangkat terlebih dahulu.');
    }
    final rows = drafts.where((row) => row['id'] != id).toList();
    rows.add({
      'id': id,
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    });
    data['drafts'] = rows;
    await persist();
  }

  Future<void> removeDraft(String id) async {
    data['drafts'] = drafts.where((r) => r['id'] != id).toList();
    await persist();
  }
}
