import 'dart:convert';

import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/data/offline_journal.dart';
import 'package:aibs_app/data/profile_repository.dart';
import 'package:aibs_app/data/records_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'cached history is used on network errors but never on denied access',
    () async {
      final local = OfflineJournal(
        'user',
        read: (_) async => null,
        write: (_, _) async {},
        remove: (_) async {},
      );
      await local.enable();
      local.data['snapshot'] = [
        {'items': []},
        [],
        {'items': []},
        {'items': []},
        [],
        {'plans': []},
      ];
      var denied = false;
      final api = ApiClient(
        baseUrl: 'http://localhost',
        accessToken: () async => 'token',
        client: MockClient((_) async {
          if (denied) {
            return http.Response('{"error":{"message":"Access denied"}}', 403);
          }
          throw http.ClientException('offline');
        }),
      );
      final records = RecordsRepository(
        api,
        ProfileRepository(api),
        offline: local,
      );
      await records.load();
      expect(records.usingCache, true);
      denied = true;
      await expectLater(records.load(), throwsA(isA<ApiFailure>()));
    },
  );
  test(
    'offline checklist conflict does not overwrite another device',
    () async {
      final local = OfflineJournal(
        'user',
        read: (_) async => null,
        write: (_, _) async {},
        remove: (_) async {},
      );
      await local.enable();
      local.data['shopping_pending'] = {
        'item': {'version': 1, 'quantity': 1, 'checked': true},
      };
      var patches = 0;
      final api = ApiClient(
        baseUrl: 'http://localhost',
        accessToken: () async => 'token',
        client: MockClient((r) async {
          if (r.method == 'PATCH') patches++;
          return http.Response(
            '{"items":[{"id":"item","version":2,"checked":false}]}',
            200,
          );
        }),
      );
      final records = RecordsRepository(
        api,
        ProfileRepository(api),
        offline: local,
      );
      await expectLater(records.syncShopping(), throwsA(isA<ApiFailure>()));
      expect(patches, 0);
      expect((local.data['shopping_pending'] as Map).length, 1);
    },
  );

  test(
    'a local commit retries the same server draft and key after app restart',
    () async {
      String? disk;
      OfflineJournal store() => OfflineJournal(
        'owner',
        read: (_) async => disk,
        write: (_, value) async {
          disk = value;
        },
        remove: (_) async {
          disk = null;
        },
      );
      final local = store();
      await local.enable();
      final content = <String, dynamic>{
        'foods': [
          {
            'name': 'Nasi',
            'consumed': true,
            'time': {
              'date': '2026-11-14',
              'precision': 'approximate',
              'period': 'midday',
              'confirmed': true,
            },
          },
        ],
      };
      await local.draft('stable-key', content);
      var creates = 0;
      var commits = 0;
      final keys = <String?>[];
      final api = ApiClient(
        baseUrl: 'http://localhost',
        accessToken: () async => 'token',
        client: MockClient((r) async {
          if (r.url.path == '/api/v1/drafts') {
            creates++;
            return http.Response('{"id":"draft-server","version":1}', 201);
          }
          keys.add(r.headers['Idempotency-Key']);
          commits++;
          if (commits == 1) throw http.ClientException('response lost');
          return http.Response('{"food_event_ids":["saved"]}', 200);
        }),
      );
      final first = RecordsRepository(
        api,
        ProfileRepository(api),
        offline: local,
      );
      await expectLater(
        first.commitLocal('stable-key', content),
        throwsA(isA<ApiFailure>()),
      );
      final restored = store();
      await restored.load();
      final second = RecordsRepository(
        api,
        ProfileRepository(api),
        offline: restored,
      );
      await second.commitLocal(
        'stable-key',
        Map<String, dynamic>.from(jsonDecode(jsonEncode(content)) as Map),
      );
      expect(creates, 1);
      expect(commits, 2);
      expect(keys, ['stable-key', 'stable-key']);
      expect(restored.drafts, isEmpty);
    },
  );
}
