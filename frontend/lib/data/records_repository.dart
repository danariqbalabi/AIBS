import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../core/demo_data.dart';
import '../shared/widgets/status_badge.dart';
import 'api_client.dart';
import 'profile_repository.dart';
import 'draft_review.dart';

const symptomCodes = {
  'Nyeri perut': 'pain',
  'Kembung': 'bloating',
  'Mual': 'nausea',
  'Muntah': 'vomiting',
  'Diare': 'diarrhea',
  'Sembelit': 'constipation',
  'BAB': 'bowel',
  'Lainnya': 'other',
};
CheckStatus statusFor(Object? value) => switch (value) {
  'ok' => CheckStatus.ok,
  'warn' => CheckStatus.warn,
  'bad' => CheckStatus.bad,
  _ => CheckStatus.unknown,
};
DateTime timeForInput(DateTime date, String time) {
  final match = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(time);
  if (match == null) throw const ApiFailure('Pilih jam yang valid.');
  var hour = int.parse(match[1]!);
  final lower = time.toLowerCase();
  if (lower.contains('am') || lower.contains('pm')) {
    hour = hour % 12 + (lower.contains('pm') ? 12 : 0);
  }
  return DateTime(date.year, date.month, date.day, hour, int.parse(match[2]!));
}

String dateLabel(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String clockLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
Map<String, dynamic> eventTime(DateTime date, String time) {
  final value = timeForInput(date, time);
  final offset = value.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  return {
    'date': dateLabel(value),
    'occurred_at':
        '${value.toIso8601String()}$sign${offset.inHours.abs().toString().padLeft(2, '0')}:${(offset.inMinutes.abs() % 60).toString().padLeft(2, '0')}',
    'precision': 'exact',
    'confirmed': true,
  };
}

class RecordsRepository {
  RecordsRepository(this.api, this.profiles);
  final ApiClient api;
  final ProfileRepository profiles;
  List<AibsMenuItem> menus = [];
  List<AibsMealLog> meals = [];
  List<AibsSymptomLog> symptoms = [];
  List<AibsStoryLog> stories = [];
  List<Map<String, dynamic>> shopping = [];
  AibsMealPlan? plan;
  Map<String, dynamic> dashboard = {};
  bool noSymptomsForLatestMeal = false;
  final _pending = <String, Map<String, dynamic>>{};

  static String ingredientLabel(Map row) =>
      '${row['display_name']} · ${row['quantity'] ?? '?'} ${row['unit'] ?? ''}'
          .trim();
  static AibsMenuItem menuFromServer(Map<String, dynamic> row) {
    final evaluation = row['evaluation'] as Map? ?? {};
    final reasons = (evaluation['reasons'] as List? ?? [])
        .map((r) => r['message'].toString())
        .toList();
    final missing = (evaluation['missing_information'] as List? ?? [])
        .cast<String>();
    final ingredients = (row['ingredients'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final instructions = row['instructions']?.toString() ?? '';
    return AibsMenuItem(
      id: row['id'] as String,
      name: row['name'] as String,
      kind: row['kind'] == 'cook' ? 'Masak' : 'Beli',
      price: row['price_rupiah'] as int,
      status: statusFor(evaluation['status']),
      reason:
          [...reasons, ...missing].firstOrNull ??
          'Sesuai arahan yang tersimpan',
      ingredients: ingredients.map(ingredientLabel).toList(),
      serverIngredients: ingredients,
      orderTips: row['kind'] == 'buy' ? [instructions] : [],
      cookSteps: row['kind'] == 'cook' ? [instructions] : [],
    );
  }

  String shoppingLabel(Map row) {
    final amount = num.parse(row['quantity'].toString());
    final quantity = amount == amount.toInt()
        ? amount.toInt().toString()
        : amount.toString();
    return '${row['name']} · $quantity ${row['unit']}';
  }

  List<String> get shoppingLabels => shopping.map(shoppingLabel).toList();
  Set<String> get checkedShopping =>
      shopping.where((r) => r['checked'] == true).map(shoppingLabel).toSet();

  Future<List<Map<String, dynamic>>> _all(String path) async {
    final rows = <Map<String, dynamic>>[];
    String? cursor;
    do {
      final result = await api.request(
        'GET',
        '$path?limit=100${cursor == null ? '' : '&cursor=${Uri.encodeQueryComponent(cursor)}'}',
      );
      rows.addAll((result['items'] as List).cast<Map<String, dynamic>>());
      cursor = result['next_cursor'] as String?;
    } while (cursor != null);
    return rows;
  }

  Future<void> load() async {
    final results = await Future.wait([
      api.request('GET', '/api/v1/menus'),
      _all('/api/v1/events'),
      api.request('GET', '/api/v1/shopping-items'),
      api.request('GET', '/api/v1/meal-plans'),
      _all('/api/v1/drafts'),
      api.request('GET', '/api/v1/dashboard'),
    ]);
    final nextMenus = ((results[0] as Map)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(menuFromServer)
        .toList();
    final events = results[1] as List<Map<String, dynamic>>;
    final nextMeals = <AibsMealLog>[];
    final nextSymptoms = <AibsSymptomLog>[];
    String time(Map payload) {
      final t = payload['time'] as Map;
      if (t['occurred_at'] != null) {
        return clockLabel(DateTime.parse(t['occurred_at'] as String).toLocal());
      }
      return '${const {'morning': 'Pagi', 'midday': 'Siang', 'late_afternoon': 'Sore', 'evening': 'Malam', 'night': 'Malam'}[t['period']] ?? 'Waktu'} · perkiraan';
    }

    for (final row in events.where((r) => r['kind'] == 'food')) {
      final payload = row['payload'] as Map;
      nextMeals.add(
        AibsMealLog(
          id: row['id'] as String,
          version: row['version'] as int,
          serverPayload: Map<String, dynamic>.from(payload),
          name: payload['name'] as String,
          date: DateTime.parse(row['local_date'] as String),
          time: time(payload),
          status: statusFor((row['evaluation'] as Map?)?['status']),
          ingredients: (payload['ingredients'] as List? ?? [])
              .map((r) => ingredientLabel(r as Map))
              .toList(),
          note: payload['ingredients_complete'] == true
              ? payload['notes'] as String?
              : 'Ada bahan yang belum diketahui',
        ),
      );
    }
    for (final row in events.where((r) => r['kind'] == 'symptom')) {
      final payload = row['payload'] as Map;
      if (payload['present'] != true) continue;
      final linked = (row['linked_event_ids'] as List? ?? [])
          .cast<String>()
          .firstOrNull;
      nextSymptoms.add(
        AibsSymptomLog(
          id: row['id'] as String,
          version: row['version'] as int,
          name:
              (payload['code'] == 'other'
                  ? payload['label'] as String?
                  : null) ??
              labelFor(symptomCodes, payload['code']) ??
              payload['code'].toString(),
          date: DateTime.parse(row['local_date'] as String),
          time: time(payload),
          severity: payload['severity'] as int?,
          serverPayload: Map<String, dynamic>.from(payload),
          note: payload['notes'] as String?,
          mealId: linked,
          mealName: nextMeals.where((m) => m.id == linked).firstOrNull?.name,
          stress: labelFor(const {
            'Rendah': 'low',
            'Sedang': 'medium',
            'Tinggi': 'high',
          }, payload['stress']),
        ),
      );
    }
    final nextStories = <AibsStoryLog>[];
    for (final row in results[4] as List<Map<String, dynamic>>) {
      final content = row['content'] as Map;
      if (content['story'] is! String || (content['story'] as String).isEmpty) {
        continue;
      }
      final date = DateTime.parse(row['created_at'] as String).toLocal();
      nextStories.add(
        AibsStoryLog(
          text: content['story'] as String,
          date: date,
          time: clockLabel(date),
        ),
      );
    }
    final plans = ((results[3] as Map)['items'] as List)
        .cast<Map<String, dynamic>>();
    plans.sort(
      (a, b) =>
          (a['scheduled_at'] as String).compareTo(b['scheduled_at'] as String),
    );
    AibsMealPlan? nextPlan;
    for (final row in plans) {
      final when = DateTime.parse(row['scheduled_at'] as String).toLocal();
      if (when.isBefore(DateTime.now())) continue;
      final menu = nextMenus.where((m) => m.id == row['menu_id']).firstOrNull;
      if (menu == null) continue;
      nextPlan = AibsMealPlan(
        menu: menu,
        day: dateLabel(when),
        meal: when.hour < 11
            ? 'Pagi'
            : when.hour < 16
            ? 'Siang'
            : 'Malam',
        time: clockLabel(when),
        scheduledAt: when,
      );
      break;
    }
    menus = nextMenus;
    meals = nextMeals;
    symptoms = nextSymptoms;
    stories = nextStories;
    plan = nextPlan;
    shopping = ((results[2] as Map)['items'] as List)
        .cast<Map<String, dynamic>>();
    dashboard = results[5] as Map<String, dynamic>;
    final latest = nextMeals.firstOrNull?.id;
    noSymptomsForLatestMeal =
        latest != null &&
        events.any(
          (row) =>
              row['kind'] == 'symptom' &&
              (row['payload'] as Map)['present'] == false &&
              (row['linked_event_ids'] as List).contains(latest),
        );
  }

  List<Map<String, dynamic>> ingredientsFor(List<String> labels) =>
      labels.map((label) {
        final pieces = label.split('·');
        final name = pieces.first.trim();
        final amount = pieces.length > 1
            ? RegExp(r'^(\d+(?:[.,]\d+)?)\s+(.+)$').firstMatch(pieces[1].trim())
            : null;
        final id = profiles.ingredientId(name);
        return <String, dynamic>{
          'ingredient_id': id,
          'display_name': name,
          'certainty': id == null ? 'unknown' : 'confirmed',
          if (amount != null) 'quantity': amount[1]!.replaceAll(',', '.'),
          if (amount != null) 'unit': amount[2],
        };
      }).toList();
  Future<void> _saveContent(String key, Map<String, dynamic> content) async {
    final signature = jsonEncode(content);
    var pending = _pending[key];
    if (pending != null && pending['signature'] != signature) {
      if (pending['committed'] == true) {
        throw const ApiFailure(
          'Catatan ini sudah tersimpan. Buat catatan baru untuk isi berbeda.',
        );
      }
      final draft = await api.request(
        'PATCH',
        '/api/v1/drafts/${pending['id']}',
        body: {
          'version': pending['version'],
          'intent': 'journal',
          'content': content,
        },
      );
      pending = {...draft, 'signature': signature};
      _pending[key] = pending;
    }
    if (pending == null) {
      final draft = await api.request(
        'POST',
        '/api/v1/drafts',
        body: {'intent': 'journal', 'content': content},
      );
      pending = {...draft, 'signature': signature};
      _pending[key] = pending;
    }
    if (pending['committed'] == true) return;
    await api.request(
      'POST',
      '/api/v1/drafts/${pending['id']}/commit',
      body: {'version': pending['version'], 'confirmed': true},
      idempotencyKey: key,
    );
    pending['committed'] = true;
  }

  Future<void> saveMeal(AibsMealLog meal) async {
    final ingredients = ingredientsFor(meal.ingredients);
    await _saveContent(meal.requestId ?? const Uuid().v4(), {
      'foods': [
        {
          'name': meal.name,
          'consumed': true,
          'time': eventTime(meal.date, meal.time),
          'ingredients': ingredients,
          'ingredients_complete':
              meal.note == null &&
              ingredients.isNotEmpty &&
              ingredients.every((i) => i['certainty'] == 'confirmed'),
          'notes': meal.note,
        },
      ],
    });
  }

  Future<Map<String, dynamic>> checkFood(
    List<String> labels,
    bool complete,
  ) async {
    final profile = await api.request('GET', '/api/v1/me/profile');
    profiles.rawProfile = profile;
    return api.request(
      'POST',
      '/api/v1/food-checks',
      body: {
        'profile_version': profile['version'],
        'ingredients': ingredientsFor(labels),
        'ingredients_complete': complete && labels.isNotEmpty,
      },
    );
  }

  Future<void> saveSymptom(AibsSymptomLog symptom) async {
    final cards = <Map<String, dynamic>>[];
    for (final name in symptom.name.split(', ')) {
      final code = symptomCodes[name];
      if (code == null) {
        throw const ApiFailure(
          'Gejala ini belum tersedia. Pilih gejala yang tercantum terlebih dahulu.',
        );
      }
      cards.add({
        'code': code,
        'present': true,
        'severity': symptom.severity,
        'time': eventTime(symptom.date, symptom.time),
        'notes': symptom.note,
        'stress': const {
          'Rendah': 'low',
          'Sedang': 'medium',
          'Tinggi': 'high',
        }[symptom.stress],
        'linked_food_event_id': symptom.mealId,
      });
    }
    await _saveContent(symptom.requestId ?? const Uuid().v4(), {
      'symptoms': cards,
    });
  }

  Future<void> saveStory(AibsStoryLog story) async {
    await api.request(
      'POST',
      '/api/v1/drafts',
      body: {
        'intent': 'journal',
        'content': {'story': story.text},
      },
    );
  }

  Future<DraftReview> analyzeStory(String text, String requestId) async {
    final result = await api.request(
      'POST',
      '/api/v1/analysis/journal',
      body: {
        'request_id': requestId,
        'text': text,
        'reference_date': dateLabel(DateTime.now()),
      },
      timeout: const Duration(seconds: 120),
    );
    return DraftReview(api, result['draft'] as Map<String, dynamic>);
  }

  Future<void> saveNoSymptoms() async {
    final food = meals
        .where((m) => dateLabel(m.date) == dateLabel(DateTime.now()))
        .firstOrNull;
    if (food?.id == null) return;
    final now = DateTime.now();
    await _saveContent('no-symptoms-${food!.id}', {
      'symptoms': [
        for (final code in symptomCodes.values)
          {
            'code': code,
            'present': false,
            'time': eventTime(now, clockLabel(now)),
            'linked_food_event_id': food.id,
          },
      ],
    });
  }

  Future<void> deleteMeal(AibsMealLog meal) async {
    if (meal.id == null || meal.version == null) {
      throw const ApiFailure('Muat ulang catatan terlebih dahulu.');
    }
    await api.request(
      'DELETE',
      '/api/v1/events/${meal.id}?version=${meal.version}',
    );
  }

  Future<void> deleteSymptom(AibsSymptomLog symptom) async {
    if (symptom.id == null || symptom.version == null) {
      throw const ApiFailure('Muat ulang catatan terlebih dahulu.');
    }
    await api.request(
      'DELETE',
      '/api/v1/events/${symptom.id}?version=${symptom.version}',
    );
  }

  Future<void> updateEvent(Map<String, dynamic> event) async {
    await api.request(
      'PATCH',
      '/api/v1/events/${event['id']}',
      body: {
        'kind': event['kind'],
        'version': event['version'],
        'payload': event['payload'],
      },
    );
  }

  Future<void> savePlan(AibsMealPlan plan) async {
    if (plan.scheduledAt == null) {
      throw const ApiFailure('Pilih tanggal rencana terlebih dahulu.');
    }
    await api.request(
      'POST',
      '/api/v1/meal-plans',
      body: {
        'menu_id': plan.menu.id,
        'scheduled_at': plan.scheduledAt!.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> addMenuShopping(AibsMenuItem menu) async {
    await api.request(
      'POST',
      '/api/v1/shopping-items/from-menu',
      body: {'menu_id': menu.id, 'servings': 1},
    );
  }

  Future<void> replaceShopping(List<String> next) async {
    final previous = shoppingLabels;
    for (final row
        in shopping.where((r) => !next.contains(shoppingLabel(r))).toList()) {
      await api.request(
        'DELETE',
        '/api/v1/shopping-items/${row['id']}?version=${row['version']}',
      );
    }
    for (final label in next.where((v) => !previous.contains(v))) {
      final parsed = ingredientsFor([label]).single;
      await api.request(
        'POST',
        '/api/v1/shopping-items',
        body: {
          'ingredient_id': parsed['ingredient_id'],
          'name': parsed['display_name'],
          'quantity': parsed['quantity'] ?? 1,
          'unit': parsed['unit'] ?? 'porsi',
        },
      );
    }
  }

  Future<void> checkShopping(String label, bool checked) async {
    final row = shopping.where((r) => shoppingLabel(r) == label).firstOrNull;
    if (row == null) throw const ApiFailure('Muat ulang daftar belanja.');
    final updated = await api.request(
      'PATCH',
      '/api/v1/shopping-items/${row['id']}',
      body: {
        'version': row['version'],
        'quantity': row['quantity'],
        'checked': checked,
      },
    );
    shopping = [
      for (final item in shopping)
        if (item['id'] == updated['id']) updated else item,
    ];
  }

  Future<Map<String, dynamic>> summary(int days) =>
      api.request('GET', '/api/v1/summaries?days=$days');
}
