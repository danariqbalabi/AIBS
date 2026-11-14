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

    await tester.tap(find.text('Nanti'));
    await tester.pumpAndSettle();
    expect(find.text('Hai, Nadia!'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Nadia'), findsOneWidget);

    await tester.tap(find.text('Arahan makan'));
    await tester.pumpAndSettle();
    expect(find.text('Arahan diet'), findsOneWidget);
    await tester.tap(find.text('Simpan perubahan'));
    await tester.pumpAndSettle();
    expect(find.text('Perubahan tersimpan untuk sesi ini'), findsOneWidget);

    await tester.tap(find.text('Menu').last);
    await tester.pumpAndSettle();
    expect(find.text('Sesuai arahanmu'), findsOneWidget);
    expect(find.text('Nasi ayam bakar kecap'), findsOneWidget);

    await tester.tap(find.text('Masak'));
    await tester.pumpAndSettle();
    expect(find.text('Tumis tahu wortel'), findsOneWidget);
    expect(find.text('Nasi ayam bakar kecap'), findsNothing);

    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nasi ayam bakar kecap'));
    await tester.pumpAndSettle();
    expect(find.text('Detail menu'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Masukkan ke checklist belanja'),
      250,
    );
    await tester.tap(find.text('Masukkan ke checklist belanja'));
    await tester.pumpAndSettle();
    expect(find.text('Checklist belanja'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Timun');
    await tester.tap(find.byTooltip('Tambah'));
    await tester.pumpAndSettle();
    expect(find.text('Timun · 1 porsi'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Foto makanan'));
    await tester.pumpAndSettle();
    expect(find.text('Foto buat apa?'), findsOneWidget);
    await tester.tap(find.text('Isi manual'));
    await tester.pumpAndSettle();
    expect(find.text('Nama makanan'), findsOneWidget);
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Foto makanan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cek sebelum makan'));
    await tester.pumpAndSettle();
    expect(find.text('Catat makanan'), findsOneWidget);
    await tester.tap(find.text('Ambil foto'));
    await tester.pumpAndSettle();
    expect(find.text('Cek hasil foto'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cek makanan'));
    await tester.pumpAndSettle();
    expect(find.text('Belum bisa dinilai'), findsOneWidget);
    await tester.tap(find.text('Simpan catatan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jurnal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ceritakan harimu'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Perut terasa kurang nyaman setelah makan siang.',
    );
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Cek hasil rapikan'), findsOneWidget);
    await tester.tap(find.text('Simpan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catat gejala'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kembung'));
    await tester.tap(find.text('Simpan catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat ringkasan'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada pola yang cukup'), findsOneWidget);
  });
}
