import 'package:aibs_app/data/offline_journal.dart';
import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/data/profile_repository.dart';
import 'package:aibs_app/data/records_repository.dart';
import 'package:aibs_app/pages/offline_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cancel disabling offline preserves unsent drafts', (
    tester,
  ) async {
    final local = OfflineJournal(
      'test',
      read: (_) async => null,
      write: (_, _) async {},
      remove: (_) async {},
    );
    await local.enable();
    await local.draft('draft', {'foods': []});
    final api = ApiClient(
      baseUrl: 'http://localhost',
      accessToken: () async => 'token',
    );
    final repo = RecordsRepository(api, ProfileRepository(api), offline: local);
    await tester.pumpWidget(MaterialApp(home: OfflinePage(records: repo)));
    await tester.tap(find.text('Simpan data di perangkat ini'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Hapus data offline?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(local.enabled, true);
    expect(local.drafts.length, 1);
  });
}
