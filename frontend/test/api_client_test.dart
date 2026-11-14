import 'dart:convert';

import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/data/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'refreshes an expired bearer and preserves commit idempotency',
    () async {
      var refreshed = false;
      final requests = <http.Request>[];
      final api = ApiClient(
        baseUrl: 'http://localhost:8000/',
        accessToken: () async => refreshed ? 'fresh' : 'expired',
        refreshSession: () async {
          refreshed = true;
        },
        client: MockClient((request) async {
          requests.add(request);
          return refreshed
              ? http.Response('{"saved":true}', 200)
              : http.Response('{"error":{"message":"expired"}}', 401);
        }),
      );
      final result = await api.request(
        'POST',
        '/api/v1/drafts/id/commit',
        body: {'version': 1, 'confirmed': true},
        idempotencyKey: 'same-save',
      );
      expect(result['saved'], true);
      expect(requests, hasLength(2));
      expect(requests.last.headers['Authorization'], 'Bearer fresh');
      expect(requests.first.body, requests.last.body);
      expect(requests.last.headers['Idempotency-Key'], 'same-save');
    },
  );

  test('returns validation failures without retrying mutations', () async {
    var calls = 0;
    final api = ApiClient(
      baseUrl: 'http://localhost:8000',
      accessToken: () async => 'token',
      client: MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'version_conflict',
              'message': 'Muat ulang data.',
            },
          }),
          409,
        );
      }),
    );
    await expectLater(
      api.request('PATCH', '/profile'),
      throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 409)),
    );
    expect(calls, 1);
  });

  test('client config rejects server credentials', () {
    expect(
      const AppConfig(
        supabaseUrl: 'https://project.supabase.co',
        publishableKey: 'sb_secret_example',
      ).error,
      isNotNull,
    );
    expect(
      const AppConfig(
        supabaseUrl: 'https://project.supabase.co',
        publishableKey: 'sb_publishable_example',
      ).error,
      isNull,
    );
  });
}
