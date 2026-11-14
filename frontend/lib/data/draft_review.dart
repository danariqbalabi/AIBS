import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

import 'api_client.dart';

/// Keeps the commit identity stable if the server reply is lost.
class DraftReview {
  DraftReview(this.api, Map<String, dynamic> draft)
    : draft = jsonDecode(jsonEncode(draft)) as Map<String, dynamic>;
  final ApiClient api;
  final Map<String, dynamic> draft;
  Map<String, dynamic> get content => draft['content'] as Map<String, dynamic>;
  Map<String, dynamic>? _pendingCommit;
  String? _commitKey;
  bool _patchUncertain = false;
  Map<String, dynamic>? _patchSnapshot;
  bool get commitPending => _pendingCommit != null || _patchUncertain;

  Future<void> save() async {
    final path = '/api/v1/drafts/${draft['id']}';
    if (_pendingCommit == null) {
      final current = await api.request('GET', path);
      if (current['persistence_status'] == 'saved') return;
      final recoveredPatch =
          _patchUncertain &&
          current['version'] == (draft['version'] as int) + 1 &&
          const DeepCollectionEquality().equals(
            current['content'],
            _patchSnapshot,
          );
      if (current['version'] != draft['version'] && !recoveredPatch) {
        throw const ApiFailure(
          'Draft berubah. Buka ulang draft sebelum menyimpan.',
          status: 409,
        );
      }
      _patchUncertain = true;
      _patchSnapshot = jsonDecode(jsonEncode(content)) as Map<String, dynamic>;
      Map<String, dynamic> updated;
      try {
        updated = recoveredPatch
            ? current
            : await api.request(
                'PATCH',
                path,
                body: {
                  'version': current['version'],
                  'intent': draft['intent'] == 'before_meal'
                      ? 'consumed'
                      : draft['intent'],
                  'content': content,
                },
              );
      } on ApiFailure catch (error) {
        if (error.status != null && error.status! < 500) {
          _patchUncertain = false;
        }
        rethrow;
      }
      _patchUncertain = false;
      draft['version'] = updated['version'];
      _pendingCommit = {'version': updated['version'], 'confirmed': true};
      _commitKey = const Uuid().v4();
    }
    try {
      await api.request(
        'POST',
        '$path/commit',
        body: _pendingCommit,
        idempotencyKey: _commitKey,
      );
    } on ApiFailure catch (error) {
      if (error.status != null && error.status! < 500) {
        _pendingCommit = null;
        _commitKey = null;
      }
      rethrow;
    }
  }
}
