import 'package:aibs_app/pages/onboarding_flow.dart';
import 'package:aibs_app/pages/link_email_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'default eight digit login accepts a pasted code without truncation',
    (tester) async {
      String? verified;
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingFlow(
            onComplete: (_) {},
            onSendCode: (_) async {},
            onVerifyCode: (_, code) async {
              verified = code;
              return false;
            },
          ),
        ),
      );
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.tap(find.text('Kirim kode'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(8));
      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(verified, isNull);
      expect(find.text('Masukkan 8 digit kode.'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '12345678');
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(verified, '12345678');
      expect(find.text('Pakai bantuan AI?'), findsOneWidget);
    },
  );

  testWidgets('eight digit email link submits the complete code', (
    tester,
  ) async {
    String? verified;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkEmailSheet(
            sendCode: (_) async {},
            verifyCode: (_, code) async {
              verified = code;
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'test@example.com');
    await tester.tap(find.text('Kirim kode'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '12345678');
    await tester.tap(find.text('Verifikasi'));
    await tester.pumpAndSettle();
    expect(verified, '12345678');
    await tester.pumpWidget(const SizedBox());
  });
}
