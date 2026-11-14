import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aibs_app/main.dart';

void main() {
  testWidgets('demo profile supports menu, meal, journal, and summary flows', (
    tester,
  ) async {
    await tester.pumpWidget(const AibsApp());
    await tester.pumpAndSettle();

    expect(find.text('Makan tenang,\nperut senang'), findsOneWidget);
    await tester.tap(find.text('Coba Demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nadia, 21'));
    await tester.pumpAndSettle();
    expect(find.text('Hai, Nadia'), findsOneWidget);

    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    expect(find.text('Sesuai arahanmu'), findsOneWidget);
    await tester.tap(find.text('Nasi ayam bakar kecap').first);
    await tester.pumpAndSettle();
    expect(find.text('Cara pesan'), findsOneWidget);

    await tester.tap(find.text('Jadwalkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan rencana'));
    await tester.pumpAndSettle();
    expect(find.text('Rencana tersimpan'), findsOneWidget);
    expect(find.text('Hai, Nadia'), findsOneWidget);
    expect(find.text('Nasi ayam bakar kecap'), findsWidgets);

    await tester.tap(find.byTooltip('Foto makanan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Isi manual'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Sup ayam');
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Saus ini kira-kira apa?'), findsOneWidget);
    await tester.tap(find.text('Cek makanan'));
    await tester.pumpAndSettle();
    expect(find.text('Belum bisa dinilai'), findsOneWidget);
    await tester.tap(find.text('Tetap catat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Waktu sudah ditinjau'));
    await tester.tap(find.text('Konfirmasi sudah dimakan'));
    await tester.pumpAndSettle();
    expect(find.text('Tersimpan'), findsOneWidget);
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jurnal').last);
    await tester.pumpAndSettle();
    expect(find.text('Sup ayam'), findsOneWidget);
    await tester.tap(find.text('Catat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catat gejala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kembung'));
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Kembung'), findsOneWidget);

    await tester.tap(find.text('Ringkasan'));
    await tester.pumpAndSettle();
    expect(find.text('Catatannya belum cukup'), findsOneWidget);
  });
}
