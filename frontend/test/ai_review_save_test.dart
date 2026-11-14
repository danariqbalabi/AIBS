import 'dart:convert';

import 'package:aibs_app/core/theme/aibs_theme.dart';
import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/data/draft_review.dart';
import 'package:aibs_app/pages/draft_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('AI review explains missing time and commits after review', (
    tester,
  ) async {
    var commits = 0;
    var requests = 0;
    final content = <String, dynamic>{
      'foods': [
        {
          'name': 'Nasi',
          'consumed': true,
          'ingredients': <dynamic>[],
          'time': {
            'date': '2026-11-14',
            'precision': 'approximate',
            'period': 'midday',
            'confirmed': false,
          },
        },
      ],
      'symptoms': <dynamic>[],
    };
    final api = ApiClient(
      baseUrl: 'https://example.test',
      accessToken: () async => 'test',
      client: MockClient((request) async {
        requests++;
        if (request.url.path.endsWith('/commit')) {
          commits++;
          return http.Response('{"persistence_status":"saved"}', 200);
        }
        if (request.method == 'PATCH') {
          final body = jsonDecode(request.body) as Map;
          expect(body['content']['foods'][0]['time']['confirmed'], true);
          return http.Response('{"version":2}', 200);
        }
        return http.Response(
          jsonEncode({'version': 1, 'content': content}),
          200,
        );
      }),
    );
    final review = DraftReview(api, {
      'id': 'draft-1',
      'version': 1,
      'intent': 'journal',
      'content': content,
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AibsTheme.light,
        home: DraftReviewPage(review: review),
      ),
    );
    await tester.tap(find.text('Simpan semua'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Makanan 1: centang Waktu'), findsOneWidget);
    expect(requests, 0);
    final time = find.text('Waktu sudah ditinjau');
    await tester.ensureVisible(time);
    await tester.pumpAndSettle();
    await tester.tap(time);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan semua'));
    await tester.pumpAndSettle();
    expect(commits, 1);
    api.close();
  });
}
