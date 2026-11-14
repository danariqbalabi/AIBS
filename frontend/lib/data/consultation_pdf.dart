import 'package:flutter/services.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/demo_data.dart';

Future<Uint8List> consultationPdf({
  required int days,
  required String directive,
  required List<AibsMealLog> meals,
  required List<AibsSymptomLog> symptoms,
  required List<String> questions,
}) async {
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Nunito-Variable.ttf'),
  );
  final document = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, text: 'Ringkasan konsultasi AIBS'),
        pw.Text('$days hari terakhir'),
        pw.Text('Arahan makan: $directive'),
        pw.Text('Catatan makan: ${meals.length}; gejala: ${symptoms.length}'),
        pw.Paragraph(
          text: 'Catatan pengguna. Belum tentu penyebab. Bukan pengganti saran dokter.',
        ),
        pw.Header(level: 1, text: 'Makanan'),
        for (final meal in meals)
          pw.Paragraph(
            text:
                '${meal.date.year}-${meal.date.month}-${meal.date.day} ${meal.time}: ${meal.name}\n${meal.ingredients.join(', ')}${meal.note == null ? '' : '\n${meal.note}'}',
          ),
        pw.Header(level: 1, text: 'Gejala'),
        for (final symptom in symptoms)
          pw.Paragraph(
            text:
                '${symptom.date.year}-${symptom.date.month}-${symptom.date.day} ${symptom.time}: ${symptom.name}, skala ${symptom.severity ?? 'belum diisi'}\n${symptom.mealName == null ? 'Tidak dihubungkan dengan makanan' : 'Dihubungkan dengan ${symptom.mealName}'}${symptom.note == null ? '' : '\n${symptom.note}'}',
          ),
        pw.Header(level: 1, text: 'Pertanyaan buat dokter'),
        for (final question in questions) pw.Bullet(text: question),
      ],
    ),
  );
  return document.save();
}
