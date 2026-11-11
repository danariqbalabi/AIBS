import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aibs_app/main.dart';

void main() {
  testWidgets('onboarding flow reaches the home screen', (tester) async {
    await tester.pumpWidget(const AibsApp());
    await tester.pumpAndSettle();

    expect(find.text('Makan lebih tenang.'), findsOneWidget);
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Nadia');
    await tester.enterText(find.byType(TextFormField).at(1), 'nadia@email.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'passwordku');
    tester.testTextInput.hide();
    await tester.tap(find.text('Daftar').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Belum didiagnosis, baru curiga'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Kita mulai dari mencatat dulu'), findsOneWidget);

    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Kamu alergi apa?'), findsOneWidget);
    await tester.tap(find.text('Kacang'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hemat'));
    await tester.tap(find.text('Tidak pedas'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Cek ulang profil'), findsOneWidget);

    await tester.tap(find.text('Simpan profil'));
    await tester.pumpAndSettle();
    expect(find.text('Hai, Nadia!'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Nadia'), findsOneWidget);

    await tester.tap(find.text('Arahan makan'));
    await tester.pumpAndSettle();
    expect(find.text('Ubah arahan diet'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi perubahan'), findsOneWidget);
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();
    expect(find.text('Perubahan tersimpan untuk sesi ini'), findsOneWidget);
  });
}
