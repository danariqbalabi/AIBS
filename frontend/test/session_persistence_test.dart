import 'dart:async';
import 'dart:convert';

import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/data/app_services.dart';
import 'package:aibs_app/data/session_identity.dart';
import 'package:aibs_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class TestIdentity implements SessionIdentity {
  @override
  bool hasSession = true;
  @override
  bool get isAnonymous => true;
  @override
  String get email => '';
  int newSessions = 0;
  int signOuts = 0;
  @override
  Future<void> signInAnonymously() async {
    hasSession = true;
    newSessions++;
  }

  @override
  Future<void> signOut() async {
    hasSession = false;
    signOuts++;
  }
}

Map<String, dynamic> get storedProfile => {
  'id': 'profile-A',
  'version': 1,
  'display_name': 'Nadia',
  'demo_template': 'nadia',
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

http.Response answer(http.Request request) {
  final path = request.url.path;
  Object body = {'items': [], 'next_cursor': null};
  if (path.endsWith('/profile')) body = storedProfile;
  if (path.endsWith('/consents')) body = {'basic': true, 'ai': false};
  if (path.endsWith('/assessment')) body = {'version': 1, 'answers': {}};
  if (path.endsWith('/dashboard')) body = {};
  if (path.endsWith('/events')) {
    final now = DateTime.now();
    body = {
      'items': [
        {
          'id': 'food-A',
          'kind': 'food',
          'version': 1,
          'local_date':
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          'payload': {
            'name': 'Catatan sebelumnya',
            'consumed': true,
            'ingredients': [],
            'time': {'occurred_at': now.toUtc().toIso8601String()},
          },
          'evaluation': {'status': 'unknown'},
          'linked_event_ids': [],
        },
      ],
      'next_cursor': null,
    };
  }
  return http.Response(jsonEncode(body), 200);
}

AppServices servicesFor(
  TestIdentity identity,
  Future<http.Response> Function(http.Request) send,
) {
  final api = ApiClient(
    baseUrl: 'http://localhost:8000',
    accessToken: () async => 'owner-A',
    client: MockClient(send),
  );
  return AppServices(api, null, identity: identity);
}

void main() {
  testWidgets(
    'refresh waits for the existing identity instead of offering a fresh demo',
    (tester) async {
      final identity = TestIdentity();
      final pending = Completer<http.Response>();
      final services = servicesFor(
        identity,
        (request) async => request.url.path.endsWith('/profile')
            ? pending.future
            : answer(request),
      );
      await tester.pumpWidget(AibsApp(services: services));
      await tester.pump();
      expect(find.text('Memulihkan sesi...'), findsOneWidget);
      expect(find.text('Coba Demo'), findsNothing);
      pending.complete(http.Response(jsonEncode(storedProfile), 200));
      await tester.pumpAndSettle();
      expect(find.text('Catatan sebelumnya'), findsOneWidget);
      expect(identity.newSessions, 0);
      expect(identity.signOuts, 0);
    },
  );

  testWidgets(
    'a failed restoration retains the session and retries the same account',
    (tester) async {
      final identity = TestIdentity();
      var fail = true;
      final services = servicesFor(identity, (request) async {
        if (fail && request.url.path.endsWith('/profile')) {
          return http.Response(
            '{"error":{"message":"Backend sementara gagal."}}',
            503,
          );
        }
        return answer(request);
      });
      await tester.pumpWidget(AibsApp(services: services));
      await tester.pumpAndSettle();
      expect(find.text('Backend sementara gagal.'), findsOneWidget);
      expect(find.text('Coba Demo'), findsNothing);
      fail = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Catatan sebelumnya'), findsOneWidget);
      expect(identity.hasSession, true);
      expect(identity.signOuts, 0);
      expect(identity.newSessions, 0);
    },
  );

  testWidgets(
    'a failed data section is an error state rather than an empty history',
    (tester) async {
      final identity = TestIdentity();
      var fail = true;
      final services = servicesFor(identity, (request) async {
        if (fail && request.url.path.endsWith('/shopping-items')) {
          return http.Response(
            '{"error":{"message":"Belanja sementara gagal."}}',
            503,
          );
        }
        return answer(request);
      });
      await tester.pumpWidget(AibsApp(services: services));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada catatan'), findsNothing);
      expect(find.text('Coba lagi'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Catatan sebelumnya'), findsOneWidget);
    },
  );

  test(
    'reselecting Nadia never signs out or creates another anonymous subject',
    () async {
      final identity = TestIdentity();
      var mutations = 0;
      final services = servicesFor(identity, (request) async {
        if (request.method != 'GET') mutations++;
        return answer(request);
      });
      await services.openDemo('nadia');
      await services.openDemo('nadia');
      expect(identity.signOuts, 0);
      expect(identity.newSessions, 0);
      expect(mutations, 0);
      await expectLater(services.openDemo('raka'), throwsA(isA<ApiFailure>()));
      expect(identity.hasSession, true);
      expect(identity.signOuts, 0);
    },
  );

  test(
    'a backend failure during demo recovery never rotates identity',
    () async {
      final identity = TestIdentity();
      final services = servicesFor(
        identity,
        (_) async => http.Response('{"error":{"message":"Coba lagi."}}', 503),
      );
      await expectLater(services.openDemo('nadia'), throwsA(isA<ApiFailure>()));
      expect(identity.hasSession, true);
      expect(identity.signOuts, 0);
      expect(identity.newSessions, 0);
    },
  );

  testWidgets('anonymous logout explains loss of access and can be cancelled', (
    tester,
  ) async {
    final identity = TestIdentity();
    final services = servicesFor(identity, (request) async => answer(request));
    await tester.pumpWidget(AibsApp(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Keluar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari demo?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(identity.signOuts, 0);
    expect(identity.hasSession, true);
  });

  test('retrying failed demo bootstrap reuses the anonymous session already created', () async {
    final identity = TestIdentity()..hasSession = false;
    var first = true;
    var bootstrapped = false;
    final services = servicesFor(identity, (request) async {
      if (request.url.path.endsWith('/demo/sessions')) {
        if (first) {
          first = false;
          return http.Response('{"error":{"message":"Retry"}}', 503);
        }
        bootstrapped = true;
        return http.Response('{}', 200);
      }
      if (request.url.path.endsWith('/profile') && !bootstrapped) {
        return http.Response(
          '{"error":{"code":"profile_missing","message":"Missing"}}',
          404,
        );
      }
      return answer(request);
    });
    await expectLater(services.openDemo('nadia'), throwsA(isA<ApiFailure>()));
    final restored = await services.openDemo('nadia');
    expect(restored.displayName, 'Nadia');
    expect(identity.newSessions, 1);
    expect(identity.signOuts, 0);
  });
}
