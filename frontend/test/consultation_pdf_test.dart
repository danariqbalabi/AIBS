import 'dart:convert';
import 'dart:io';

import 'package:aibs_app/core/demo_data.dart';
import 'package:aibs_app/data/consultation_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'consultation creates a PDF with unknown severity and user questions',
    () async {
      final bytes = await consultationPdf(
        days: 30,
        directive: 'Low FODMAP',
        meals: const [],
        symptoms: [
          AibsSymptomLog(
            name: 'Mual',
            time: 'Sore',
            date: DateTime(2026, 11, 14),
            severity: null,
          ),
        ],
        questions: ['Apakah porsi perlu ditinjau?'],
      );
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      final directory = Directory.systemTemp.createTempSync('aibs-pdf-test-');
      try {
        final file = File('${directory.path}/consultation.pdf');
        await file.writeAsBytes(bytes);
        expect(await file.length(), greaterThan(1000));
      } finally {
        directory.deleteSync(recursive: true);
      }
    },
  );
}
