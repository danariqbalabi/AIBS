import 'package:flutter/material.dart';

import '../core/theme/aibs_tokens.dart';
import '../data/app_services.dart';
import '../shared/widgets/status_badge.dart';

class FoodSwapsPage extends StatefulWidget {
  const FoodSwapsPage({super.key, required this.card, required this.load});
  final Map<String, dynamic> card;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) load;
  @override
  State<FoodSwapsPage> createState() => _FoodSwapsPageState();
}

class _FoodSwapsPageState extends State<FoodSwapsPage> {
  late Future<Map<String, dynamic>> task = widget.load(widget.card);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pengganti bahan')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: task,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppServices.message(snapshot.error!)),
                TextButton(
                  onPressed: () =>
                      setState(() => task = widget.load(widget.card)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!['items'] as List;
        return ListView(
          padding: const EdgeInsets.all(AibsSpace.s20),
          children: [
            Text(snapshot.data!['notice'].toString()),
            const SizedBox(height: AibsSpace.s16),
            if (items.isEmpty)
              const Text(
                'Belum ada pengganti yang sesuai untuk seluruh bahan dan profil ini. Coba ubah bahan atau porsi secara manual.',
              ),
            for (final item in items)
              ListTile(
                title: Text('${item['from']} → ${item['to']}'),
                subtitle: const StatusBadge(CheckStatus.ok),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(
                  context,
                  Map<String, dynamic>.from(item['card'] as Map),
                ),
              ),
          ],
        );
      },
    ),
  );
}
