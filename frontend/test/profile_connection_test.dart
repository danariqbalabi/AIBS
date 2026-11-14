import 'dart:convert';

import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/data/profile_repository.dart';
import 'package:aibs_app/pages/profile_setup_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ProfileSetupAnswers profile({
  List<String> allergies = const [],
  int? serverVersion,
}) => ProfileSetupAnswers(
  displayName: 'Tester',
  email: 'tester@example.com',
  ageBand: '18–29',
  diagnosis: 'Tidak',
  clinicianGuidance: 'Tidak',
  redFlags: const ['Tidak', null, null, null, null],
  pattern: const ['Ya', '3–4 hari', '6–12 bulan', 'Ya', 'Ya', 'Tidak'],
  dietType: null,
  dietPhase: null,
  avoidedIngredients: const [],
  portionLimits: const {},
  allergies: allergies,
  tolerances: const [],
  budget: null,
  spicy: null,
  preferences: const [],
  aiEnabled: false,
  serverVersion: serverVersion,
);

void main() {
  test(
    'saving onboarding persists its range answers without manufacturing months',
    () async {
      Map? savedAnswers;
      final raw = <String, dynamic>{
        'id': 'profile',
        'version': 1,
        'display_name': 'Tester',
        'age_band': '18_29',
        'diet': {
          'directive': 'none',
          'phase': 'unknown',
          'allergies': [],
          'avoided_ingredients': [],
          'tolerances': [],
          'portion_limits': [],
          'preferences': [],
        },
      };
      final api = ApiClient(
        baseUrl: 'http://localhost:8000',
        accessToken: () async => 'token',
        client: MockClient((request) async {
          final path = request.url.path;
          Object result = raw;
          if (path.endsWith('/consents')) result = {'basic': true, 'ai': false};
          if (path.endsWith('/assessment')) {
            if (request.method == 'PATCH') {
              savedAnswers =
                  (jsonDecode(request.body) as Map)['answers'] as Map;
            }
            result = {'version': 2, 'answers': savedAnswers ?? {}};
          }
          if (path.endsWith('/evaluate')) result = {'route': 'logging_only'};
          return http.Response(jsonEncode(result), 200);
        }),
      );
      final repo = ProfileRepository(api)
        ..ingredients = [
          {'id': 'catalog-item', 'name': 'Nasi', 'aliases': []},
        ];
      await repo.save(profile());
      expect(savedAnswers!['q3_months'], isNull);
      expect(savedAnswers!['q3_band'], '6_12');
      expect(savedAnswers!['q2_band'], '3_4');
      expect(savedAnswers!['severe_active'], 'no');
    },
  );

  test('an unknown allergy is rejected rather than silently dropped', () async {
    var calls = 0;
    final api = ApiClient(
      baseUrl: 'http://localhost:8000',
      accessToken: () async => 'token',
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    final repo = ProfileRepository(api)
      ..ingredients = [
        {'id': 'rice', 'name': 'Nasi', 'aliases': []},
      ];
    await expectLater(
      repo.save(profile(allergies: ['Bahan belum dikenal'])),
      throwsA(isA<ApiFailure>()),
    );
    expect(calls, 0);
  });

  test(
    'stale profile edits are rejected before consent or profile writes',
    () async {
      final methods = <String>[];
      final api = ApiClient(
        baseUrl: 'http://localhost:8000',
        accessToken: () async => 'token',
        client: MockClient((request) async {
          methods.add(request.method);
          return http.Response('{"version":2}', 200);
        }),
      );
      final repo = ProfileRepository(api);
      await expectLater(
        repo.save(profile(serverVersion: 1)),
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 409)),
      );
      expect(methods, ['GET']);
    },
  );
}
