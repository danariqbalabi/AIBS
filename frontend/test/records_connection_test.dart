import 'dart:convert';

import 'package:aibs_app/core/demo_data.dart';
import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/data/profile_repository.dart';
import 'package:aibs_app/data/records_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'a lost commit response retries the same draft and idempotency key',
    () async {
      var drafts = 0;
      var commits = 0;
      final keys = <String?>[];
      final api = ApiClient(
        baseUrl: 'http://localhost:8000',
        accessToken: () async => 'token',
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/drafts') {
            drafts++;
            final content = (jsonDecode(request.body) as Map)['content'];
            expect(content['foods'][0]['consumed'], true);
            expect(content['foods'][0]['time']['confirmed'], true);
            return http.Response('{"id":"draft-1","version":1}', 201);
          }
          commits++;
          keys.add(request.headers['Idempotency-Key']);
          if (commits == 1) throw http.ClientException('lost response');
          return http.Response(
            '{"persistence_status":"saved","food_event_ids":["food-saved"]}',
            200,
          );
        }),
      );
      final repo = RecordsRepository(api, ProfileRepository(api));
      final meal = AibsMealLog(
        name: 'Nasi',
        time: '12:15',
        date: DateTime(2026, 11, 14),
        requestId: 'save-one',
      );
      await expectLater(repo.saveMeal(meal), throwsA(isA<ApiFailure>()));
      expect(await repo.saveMeal(meal), 'food-saved');
      expect(await repo.saveMeal(meal), 'food-saved');
      expect(drafts, 1);
      expect(commits, 2);
      expect(keys, ['save-one', 'save-one']);
    },
  );

  test(
    'symptom multi-select sends separate cards linked by server event ID',
    () async {
      Map? saved;
      final api = ApiClient(
        baseUrl: 'http://localhost:8000',
        accessToken: () async => 'token',
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/drafts') {
            saved = jsonDecode(request.body) as Map;
            return http.Response('{"id":"draft-2","version":1}', 201);
          }
          return http.Response('{}', 200);
        }),
      );
      final repo = RecordsRepository(api, ProfileRepository(api));
      await repo.saveSymptom(
        AibsSymptomLog(
          name: 'Kembung, Mual',
          time: '15:00',
          date: DateTime(2026, 11, 14),
          severity: 2,
          mealId: 'food-server-id',
          requestId: 'save-symptom',
        ),
      );
      final cards = saved!['content']['symptoms'] as List;
      expect(cards.map((c) => c['code']), ['bloating', 'nausea']);
      expect(
        cards.every((c) => c['linked_food_event_id'] == 'food-server-id'),
        true,
      );
    },
  );

  test('24 hour noon is preserved rather than interpreted as midnight', () {
    expect(timeForInput(DateTime(2026, 11, 14), '12:15').hour, 12);
    expect(timeForInput(DateTime(2026, 11, 14), '12:15 AM').hour, 0);
    expect(timeForInput(DateTime(2026, 11, 14), '1:15 PM').hour, 13);
  });
}
