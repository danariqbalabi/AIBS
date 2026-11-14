import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/data/app_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aibs_app/pages/onboarding_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SMTP errors are distinguishable without revealing the raw provider response', () {
    final message = AppServices.message(
      const AuthException(
        'Error sending confirmation email: private diagnostic',
        statusCode: '500',
      ),
    );
    expect(message, contains('SMTP'));
    expect(message, isNot(contains('private diagnostic')));
    expect(
      AppServices.message(
        const AuthException('Internal failure', code: 'unexpected_failure'),
      ),
      isNot(contains('SMTP')),
    );
  });

  testWidgets(
    'failed email delivery keeps the email and does not show the OTP form',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlow(
            onComplete: (_) {},
            onSendCode: (_) async {
              throw const AuthException(
                'Error sending confirmation email',
                statusCode: '500',
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'tester@example.com');
      await tester.tap(find.text('Kirim kode'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Periksa pengaturan SMTP'), findsOneWidget);
      expect(find.text('tester@example.com'), findsOneWidget);
      expect(find.text('Masukkan kode'), findsNothing);
    },
  );
  testWidgets(
    'invalid server OTP keeps the code form and never completes login',
    (tester) async {
      var completed = false;
      var sent = false;
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlow(
            onComplete: (_) => completed = true,
            onSendCode: (_) async {
              sent = true;
            },
            onVerifyCode: (_, code) async {
              expect(code, '123456');
              throw const ApiFailure('Kode tidak valid.', status: 401);
            },
            otpLength: 6,
          ),
        ),
      );
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'tester@example.com');
      await tester.tap(find.text('Kirim kode'));
      await tester.pumpAndSettle();
      expect(sent, true);
      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byType(TextField).at(i), '${i + 1}');
      }
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Kode tidak valid.'), findsOneWidget);
      expect(find.text('Masukkan kode'), findsOneWidget);
      expect(completed, false);
    },
  );
}
