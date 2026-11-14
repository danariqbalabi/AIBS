import '../shared/widgets/status_badge.dart';

class AibsMenuItem {
  const AibsMenuItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.price,
    required this.status,
    required this.reason,
    required this.ingredients,
    this.orderTips = const [],
    this.cookSteps = const [],
    this.serverIngredients = const [],
  });

  final String id;
  final String name;
  final String kind;
  final int price;
  final CheckStatus status;
  final String reason;
  final List<String> ingredients;
  final List<String> orderTips;
  final List<String> cookSteps;
  final List<Map<String, dynamic>> serverIngredients;

  String get priceLabel => 'Rp${price ~/ 1000}.000';
  String get meta => '$kind · $priceLabel · $reason';
}

const aibsDemoMenus = [
  AibsMenuItem(
    id: 'ayam-bakar',
    name: 'Nasi ayam bakar kecap',
    kind: 'Beli',
    price: 22000,
    status: CheckStatus.ok,
    reason: 'tanpa bawang',
    ingredients: [
      'Nasi putih · 1 porsi',
      'Ayam paha · 100 g',
      'Kecap manis · 1 sdm',
      'Jahe · 1 ruas',
      'Timun · 3 iris',
    ],
    orderTips: ['Minta tanpa sambal bawang', 'Nasi cukup 1 porsi'],
  ),
  AibsMenuItem(
    id: 'tahu-wortel',
    name: 'Tumis tahu wortel',
    kind: 'Masak',
    price: 15000,
    status: CheckStatus.ok,
    reason: 'tanpa bawang',
    ingredients: [
      'Tahu putih · 2 potong',
      'Wortel · 1 buah',
      'Minyak · 1 sdt',
      'Garam · secukupnya',
    ],
    cookSteps: [
      'Potong tahu dan wortel.',
      'Tumis dengan sedikit minyak sampai matang.',
      'Tambahkan garam secukupnya.',
    ],
  ),
  AibsMenuItem(
    id: 'sup-ayam',
    name: 'Sup ayam jahe',
    kind: 'Beli',
    price: 18000,
    status: CheckStatus.ok,
    reason: 'sesuai arahan',
    ingredients: [
      'Ayam · 100 g',
      'Wortel · ½ buah',
      'Jahe · 1 ruas',
      'Kaldu · 1 mangkuk',
    ],
    orderTips: ['Tanyakan bumbu kaldu', 'Nasi terpisah'],
  ),
  AibsMenuItem(
    id: 'nasi-goreng',
    name: 'Nasi goreng telur',
    kind: 'Beli',
    price: 18000,
    status: CheckStatus.warn,
    reason: 'nasi 1½ porsi',
    ingredients: [
      'Nasi putih · 1½ porsi',
      'Telur · 1 butir',
      'Kecap manis · 1 sdm',
      'Bumbu · belum jelas',
    ],
    orderTips: ['Minta nasi 1 porsi', 'Tanyakan bumbu yang digunakan'],
  ),
  AibsMenuItem(
    id: 'soto-santan',
    name: 'Soto ayam santan',
    kind: 'Beli',
    price: 20000,
    status: CheckStatus.bad,
    reason: 'ada bawang putih',
    ingredients: ['Ayam · 100 g', 'Santan · 1 mangkuk', 'Bawang putih · bumbu'],
    orderTips: ['Bawang putih tercantum di bumbu'],
  ),
];

class AibsMealLog {
  const AibsMealLog({
    required this.name,
    required this.time,
    required this.date,
    this.status = CheckStatus.unknown,
    this.ingredients = const [],
    this.note,
    this.id,
    this.version,
    this.requestId,
    this.serverPayload,
  });

  final String name;
  final String time;
  final DateTime date;
  final CheckStatus status;
  final List<String> ingredients;
  final String? note;
  final String? id;
  final int? version;
  final String? requestId;
  final Map<String, dynamic>? serverPayload;
}

class AibsSymptomLog {
  const AibsSymptomLog({
    required this.name,
    required this.time,
    required this.date,
    required this.severity,
    this.stress,
    this.note,
    this.mealName,
    this.id,
    this.version,
    this.mealId,
    this.requestId,
    this.serverPayload,
  });

  final String name;
  final String time;
  final DateTime date;
  final int? severity;
  final String? stress;
  final String? note;
  final String? mealName;
  final String? id;
  final int? version;
  final String? mealId;
  final String? requestId;
  final Map<String, dynamic>? serverPayload;
}

class AibsStoryLog {
  const AibsStoryLog({
    required this.text,
    required this.time,
    required this.date,
    this.draftId,
    this.version,
    this.title,
  });

  final String text;
  final String? draftId;
  final int? version;
  final String? title;
  final String time;
  final DateTime date;
}

class AibsMealPlan {
  const AibsMealPlan({
    required this.menu,
    required this.day,
    required this.meal,
    required this.time,
    this.scheduledAt,
  });

  final AibsMenuItem menu;
  final DateTime? scheduledAt;
  final String day;
  final String meal;
  final String time;
}

String formatRupiah(int amount) {
  final value = amount.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < value.length; index++) {
    if (index > 0 && (value.length - index) % 3 == 0) buffer.write('.');
    buffer.write(value[index]);
  }
  return 'Rp$buffer';
}
