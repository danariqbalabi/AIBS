import 'dart:convert';

import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/data/draft_review.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('lost commit response replays the same version and key without patching again', () async {
    var patches = 0;
    var commits = 0;
    String? key;
    String? body;
    final api = ApiClient(
      baseUrl: 'https://api.example',
      accessToken: () async => 'test',
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({'version': 1, 'persistence_status': 'draft'}),
            200,
          );
        }
        if (request.method == 'PATCH') {
          patches++;
          final content = jsonDecode(request.body)['content'];
          expect(content['symptoms'][0]['present'], false);
          expect(content['symptoms'][0]['severity'], null);
          return http.Response('{"version":2}', 200);
        }
        commits++;
        if (commits == 1) {
          key = request.headers['Idempotency-Key'];
          body = request.body;
          throw http.ClientException('reply lost');
        }
        expect(request.headers['Idempotency-Key'], key);
        expect(request.body, body);
        return http.Response('{"persistence_status":"saved"}', 200);
      }),
    );
    final review = DraftReview(api, {
      'id': 'draft-1',
      'intent': 'journal',
      'content': {
        'symptoms': [
          {'code': 'nausea', 'present': false, 'severity': null},
        ],
      },
    });
    await expectLater(review.save(), throwsA(isA<ApiFailure>()));
    expect(review.commitPending, true);
    await review.save();
    expect(patches, 1);
    expect(commits, 2);
    api.close();
  });
}
