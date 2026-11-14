import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/data/profile_repository.dart';
import 'package:aibs_app/data/records_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('AI off rejects photo analysis before any upload', () async {
    var requests = 0;
    final api = ApiClient(
      baseUrl: 'https://example.test',
      accessToken: () async => 'test',
      client: MockClient((request) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    final profiles = ProfileRepository(api)..consent = {'ai': false};
    await expectLater(
      RecordsRepository(api, profiles).analyzePhoto([1, 2], 'request', true),
      throwsA(isA<ApiFailure>()),
    );
    expect(requests, 0);
    api.close();
  });

  test(
    'multipart upload refreshes authorization and keeps file bytes',
    () async {
      var requests = 0;
      var token = 'old';
      final api = ApiClient(
        baseUrl: 'https://example.test',
        accessToken: () async => token,
        refreshSession: () async {
          token = 'new';
        },
        client: MockClient((request) async {
          requests++;
          expect(
            request.headers['content-type'],
            contains('multipart/form-data'),
          );
          expect(request.body, contains('name="file"; filename="food.jpg"'));
          expect(request.body, contains('photo-content'));
          return http.Response(
            requests == 1
                ? '{"error":{"message":"expired"}}'
                : '{"id":"media-1"}',
            requests == 1 ? 401 : 201,
          );
        }),
      );
      final result = await api.request(
        'POST',
        '/api/v1/media',
        fileBytes: 'photo-content'.codeUnits,
      );
      expect(result['id'], 'media-1');
      expect(requests, 2);
      api.close();
    },
  );
}
