import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/pages/onboarding_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
