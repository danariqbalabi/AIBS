import 'package:aibs_app/data/api_client.dart';
import 'package:aibs_app/pages/link_email_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('an invalid OTP keeps the linking form and original email', (
    tester,
  ) async {
    var sent = '';
    var verified = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkEmailSheet(
            sendCode: (email) async {
              sent = email;
            },
            verifyCode: (email, code) async {
              expect(email, 'tester@example.com');
              expect(code, '123456');
              throw const ApiFailure('Kode tidak valid.');
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'tester@example.com');
    await tester.tap(find.text('Kirim kode'));
    await tester.pumpAndSettle();
    expect(sent, 'tester@example.com');
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Verifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Kode tidak valid.'), findsOneWidget);
    expect(find.text('Hubungkan email'), findsOneWidget);
    expect(verified, false);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sending failure never advances to a code screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkEmailSheet(
            sendCode: (_) async {
              throw const ApiFailure('Email belum terkirim.');
            },
            verifyCode: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'tester@example.com');
    await tester.tap(find.text('Kirim kode'));
    await tester.pumpAndSettle();
    expect(find.text('Email belum terkirim.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
