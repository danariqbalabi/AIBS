import 'package:flutter/material.dart';

import '../core/demo_data.dart';
import '../core/theme/aibs_tokens.dart';
import '../data/records_repository.dart';

class JournalTimelinePage extends StatefulWidget {
  const JournalTimelinePage({
    super.key,
    required this.meals,
    required this.symptoms,
    this.onOpenEvidence,
  });
  final List<AibsMealLog> meals;
  final List<AibsSymptomLog> symptoms;
  final void Function(DateTime, String)? onOpenEvidence;
  @override
  State<JournalTimelinePage> createState() => _JournalTimelinePageState();
}

class _JournalTimelinePageState extends State<JournalTimelinePage> {
  DateTime day = DateUtils.dateOnly(DateTime.now());
  @override
  Widget build(BuildContext context) {
    final meals = widget.meals
        .where((m) => DateUtils.isSameDay(m.date, day))
        .toList();
    final symptoms = widget.symptoms
        .where((s) => DateUtils.isSameDay(s.date, day))
        .toList();
    final entries = <({String title, String time, int? severity, bool food})>[
      for (final m in meals)
        (title: m.name, time: m.time, severity: null, food: true),
      for (final s in symptoms)
        (title: s.name, time: s.time, severity: s.severity, food: false),
    ]..sort((a, b) => a.time.compareTo(b.time));
    final bins = List.generate(6, (_) => [0, 0]);
    int approximate = 0;
    for (final entry in entries) {
      final exact = RegExp(r'^(\d{1,2})[:.](\d{2})$').firstMatch(entry.time);
      if (exact == null) {
        approximate++;
        continue;
      }
      final hour = int.parse(exact[1]!);
      if (hour < 24) bins[hour ~/ 4][entry.food ? 0 : 1]++;
    }
    final peak = bins.expand((b) => b).fold<int>(1, (a, b) => a > b ? a : b);
    return Scaffold(
      appBar: AppBar(title: const Text('Grafik harian')),
      body: ListView(
        padding: const EdgeInsets.all(AibsSpace.s20),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Hari sebelumnya',
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    setState(() => day = day.subtract(const Duration(days: 1))),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final selected = await showDatePicker(
                      context: context,
                      initialDate: day,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (selected != null) setState(() => day = selected);
                  },
                  child: Text(dateLabel(day)),
                ),
              ),
              IconButton(
                tooltip: 'Hari berikutnya',
                icon: const Icon(Icons.chevron_right),
                onPressed: day.isBefore(DateUtils.dateOnly(DateTime.now()))
                    ? () =>
                          setState(() => day = day.add(const Duration(days: 1)))
                    : null,
              ),
            ],
          ),
          Text(
            'Belum tentu penyebab',
            style: context.aibsText(AibsType.caption),
          ),
          const SizedBox(height: AibsSpace.s20),
          Text(
            'Jumlah catatan per 4 jam',
            style: context.aibsText(AibsType.bodyStrong),
          ),
          const Text('Makan: biru · Gejala: abu-abu'),
          const SizedBox(height: AibsSpace.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < bins.length; i++)
                Expanded(
                  child: Semantics(
                    label:
                        '${i * 4} sampai ${i * 4 + 4}: ${bins[i][0]} makan, ${bins[i][1]} gejala',
                    child: Column(
                      children: [
                        SizedBox(
                          height: AibsSize.dailyChartHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var kind = 0; kind < 2; kind++)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AibsSpace.s2,
                                    ),
                                    child: Container(
                                      height:
                                          AibsSize.dailyChartHeight *
                                          bins[i][kind] /
                                          peak,
                                      decoration: BoxDecoration(
                                        color: context.aibsColor(
                                          kind == 0
                                              ? AibsColors.primary
                                              : AibsColors.inkMuted,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AibsRadius.sm,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '${i * 4}',
                          style: context.aibsText(AibsType.micro),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (approximate > 0)
            Text(
              '$approximate catatan dengan jam perkiraan ditampilkan di daftar, tidak diplot sebagai jam pasti.',
            ),
          const SizedBox(height: AibsSpace.s20),
          if (entries.isEmpty)
            const Text('Belum ada catatan pada tanggal ini.'),
          for (final e in entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                e.food ? Icons.restaurant : Icons.favorite_border,
                color: context.aibsColor(AibsColors.primary),
              ),
              title: Text(e.title),
              subtitle: Text(e.time),
              trailing: e.food
                  ? null
                  : SizedBox(
                      width: AibsSize.menuArtworkIcon,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.severity == null ? '?' : '${e.severity}/5'),
                          LinearProgressIndicator(value: (e.severity ?? 0) / 5),
                        ],
                      ),
                    ),
              onTap: widget.onOpenEvidence == null
                  ? null
                  : () => widget.onOpenEvidence!(day, e.food ? '' : e.title),
            ),
        ],
      ),
    );
  }
}
