import 'dart:convert';

import 'package:aibs_app/data/offline_journal.dart';
import 'package:aibs_app/data/journal_csv.dart';
import 'package:aibs_app/core/demo_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'offline data is opt-in, isolated by subject, and removed on clear',
    () async {
      final disk = <String, String>{};
      OfflineJournal store(String owner) => OfflineJournal(
        owner,
        read: (key) async => disk[key],
        write: (key, value) async {
          disk[key] = value;
        },
        remove: (key) async {
          disk.remove(key);
        },
      );
      final alice = store('alice');
      await expectLater(
        alice.draft('draft-1', {'foods': []}),
        throwsStateError,
      );
      await alice.enable();
      await alice.draft('draft-1', {
        'foods': [
          {'name': 'Nasi'},
        ],
      });
      await alice.draft('draft-1', {
        'foods': [
          {'name': 'Ayam'},
        ],
      });
      final restored = store('alice');
      await restored.load();
      expect(restored.drafts.length, 1);
      expect(restored.drafts.single['content']['foods'][0]['name'], 'Ayam');
      final bob = store('bob');
      await bob.load();
      expect(bob.drafts, isEmpty);
      await alice.clear();
      await restored.load();
      expect(restored.enabled, false);
      expect(restored.drafts, isEmpty);
    },
  );
  test(
    'CSV escapes commas quotes and formulas and preserves unknown severity',
    () {
      final bytes = journalCsv(
        [
          AibsMealLog(
            name: '=SUM(1,2)',
            date: DateTime(2026, 11, 14),
            time: '12:00',
            note: 'a,"b"',
          ),
        ],
        [
          AibsSymptomLog(
            name: 'Gas',
            date: DateTime(2026, 11, 14),
            time: '13:00',
            severity: null,
          ),
        ],
      );
      final csv = utf8.decode(bytes);
      expect(bytes.take(3).toList(), [0xef, 0xbb, 0xbf]);
      expect(csv, contains("${String.fromCharCode(39)}=SUM(1,2)"));
      expect(csv, contains('"a,""b"""'));
      expect(csv, contains('"Gas","",""'));
    },
  );
}
