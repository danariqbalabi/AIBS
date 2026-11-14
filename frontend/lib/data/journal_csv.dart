import 'dart:convert';
import 'dart:typed_data';

import '../core/demo_data.dart';

String csvCell(Object? value) {
  var text = value?.toString() ?? '';
  if (RegExp(r'^\s*[=+@\-\t\r]').hasMatch(text)) text = "'$text";
  return '"${text.replaceAll('"', '""')}"';
}

Uint8List journalCsv(List<AibsMealLog> meals, List<AibsSymptomLog> symptoms) {
  final rows = <List<Object?>>[
    [
      'id',
      'jenis',
      'tanggal',
      'waktu',
      'nama',
      'bahan',
      'skala_1_5',
      'id_makanan_terhubung',
      'catatan',
    ],
    for (final m in meals)
      [
        m.id,
        'makan',
        m.date.toIso8601String().split('T').first,
        m.time,
        m.name,
        m.ingredients.join('; '),
        '',
        '',
        m.note,
      ],
    for (final s in symptoms)
      [
        s.id,
        'gejala',
        s.date.toIso8601String().split('T').first,
        s.time,
        s.name,
        '',
        s.severity,
        s.mealId,
        s.note,
      ],
  ];
  return Uint8List.fromList([
    0xef,
    0xbb,
    0xbf,
    ...utf8.encode(rows.map((row) => row.map(csvCell).join(',')).join('\r\n')),
  ]);
}
