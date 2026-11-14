import 'dart:convert';

import 'package:uuid/uuid.dart';

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
  bool get commitPending => _pendingCommit != null;

  Future<void> save() async {
    final path = '/api/v1/drafts/${draft['id']}';
    if (_pendingCommit == null) {
      final current = await api.request('GET', path);
      if (current['persistence_status'] == 'saved') return;
      final updated = await api.request(
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
