import '../core/demo_data.dart';
import '../pages/profile_setup_flow.dart';
import 'api_client.dart';

const dietCodes = {
  'Low FODMAP': 'low_fodmap',
  'Rendah lemak': 'low_fat',
  'Tinggi serat': 'high_fiber',
  'Lainnya': 'other',
  'Belum ada arahan': 'none',
};
const phaseCodes = {
  'Eliminasi': 'elimination',
  'Reintroduksi': 'reintroduction',
  'Personalisasi': 'personalization',
  'Belum tahu': 'unknown',
};
const ageCodes = {
  'Di bawah 18': 'under_18',
  '18–29': '18_29',
  '30–39': '30_39',
  '40–49': '40_49',
  '50 ke atas': '50_plus',
};
const spicyCodes = {
  'Nggak pedas': 'none',
  'Sedikit': 'little',
  'Sedang': 'medium',
  'Pedas banget': 'hot',
};
const answerCodes = {'Ya': 'yes', 'Tidak': 'no', 'Tidak tahu': 'unknown'};

String? labelFor(Map<String, String> codes, Object? code) {
  for (final entry in codes.entries) {
    if (entry.value == code) return entry.key;
  }
  return null;
}

class ProfileRepository {
  ProfileRepository(this.api);
  final ApiClient api;
  Map<String, dynamic>? rawProfile;
  Map<String, dynamic> consent = {};
  Map<String, dynamic> assessment = {};
  List<Map<String, dynamic>> ingredients = [];

  void clear() {
    rawProfile = null;
    ingredients = [];
    consent = {};
    assessment = {};
  }

  Future<void> loadIngredients() async {
    final result = await api.request('GET', '/api/v1/ingredients');
    ingredients = (result['items'] as List).cast<Map<String, dynamic>>();
  }

  String? ingredientId(String name) {
    final needle = name.trim().toLowerCase();
    for (final row in ingredients) {
      final names = [row['name'], ...row['aliases'] as List];
      if (names.any((n) => n.toString().toLowerCase() == needle)) {
        return row['id'] as String;
      }
    }
    return null;
  }

  String ingredientName(Object id) =>
      ingredients.firstWhere(
            (row) => row['id'] == id,
            orElse: () => {'name': 'Bahan belum dikenal'},
          )['name']
          as String;

  List<String> _ids(List<String> names) => names.map((name) {
    final id = ingredientId(name);
    if (id == null) {
      throw ApiFailure(
        'Bahan "$name" belum tersedia di katalog. Pilih bahan katalog terlebih dahulu.',
      );
    }
    return id;
  }).toList();

  Future<ProfileSetupAnswers?> restore(String email) async {
    try {
      rawProfile = await api.request('GET', '/api/v1/me/profile');
    } on ApiFailure catch (e) {
      if (e.code == 'profile_missing') return null;
      rethrow;
    }
    consent = await api.request('GET', '/api/v1/me/consents');
    if (consent['basic'] != true) return null;
    await loadIngredients();
    assessment = await api.request('GET', '/api/v1/me/assessment');
    // A profile initialized only to evaluate screening is not a completed onboarding.
    if (rawProfile!['display_name'] == 'Kamu' &&
        rawProfile!['demo_template'] == null) {
      return null;
    }
    return fromServer(email);
  }

  ProfileSetupAnswers fromServer(String email) {
    final row = rawProfile!;
    final diet = row['diet'] as Map<String, dynamic>;
    final answers = assessment['answers'] as Map? ?? {};
    List<String> names(String key) => (diet[key] as List? ?? [])
        .map((id) => ingredientName(id as Object))
        .toList();
    return ProfileSetupAnswers(
      displayName: row['display_name'] as String,
      email: email,
      ageBand: labelFor(ageCodes, row['age_band']),
      diagnosis: labelFor(answerCodes, row['diagnosis_reported']),
      clinicianGuidance: labelFor(answerCodes, row['clinician_guidance']),
      redFlags: [
        'severe_active',
        'bleeding',
        'weight_loss',
        'anemia',
        'family_history',
      ].map((key) => labelFor(answerCodes, answers[key])).toList(),
      pattern: [
        labelFor(answerCodes, answers['q1']),
        labelFor(const {
              'Kurang dari 1 hari': 'under_1',
              '1–2 hari': '1_2',
              '3–4 hari': '3_4',
              '5 hari atau lebih': '5_plus',
              'Tidak tahu': 'unknown',
            }, answers['q2_band']) ??
            (answers['q2_days'] == null ? null : '${answers['q2_days']} hari'),
        labelFor(const {
              'Kurang dari 3 bulan': 'under_3',
              '3–5 bulan': '3_5',
              '6–12 bulan': '6_12',
              'Lebih dari 12 bulan': 'over_12',
              'Tidak tahu': 'unknown',
            }, answers['q3_band']) ??
            (answers['q3_months'] == null
                ? null
                : '${answers['q3_months']} bulan'),
        ...['q4', 'q5', 'q6'].map((key) => labelFor(answerCodes, answers[key])),
      ],
      dietType: labelFor(dietCodes, diet['directive']),
      dietPhase: labelFor(phaseCodes, diet['phase']),
      avoidedIngredients: names('avoided_ingredients'),
      portionLimits: {
        for (final limit in diet['portion_limits'] as List? ?? [])
          ingredientName(limit['ingredient_id']): num.parse(
            limit['quantity'].toString(),
          ).toInt(),
      },
      allergies: names('allergies'),
      tolerances: names('tolerances'),
      budget: diet['budget_rupiah'] == null
          ? null
          : formatRupiah(diet['budget_rupiah'] as int),
      spicy: labelFor(spicyCodes, diet['spicy']),
      preferences: (diet['preferences'] as List? ?? []).cast<String>(),
      aiEnabled: consent['ai'] == true,
      savePhotos: row['save_photos'] == true,
      serverVersion: row['version'] as int?,
    );
  }

  Future<void> ensureConsent(bool ai) async {
    await api.request('POST', '/api/v1/me/profile');
    consent = await api.request(
      'PUT',
      '/api/v1/me/consents',
      body: {'basic': true, 'ai': ai, 'policy_version': 'demo-v1'},
    );
  }

  Future<ProfileSetupAnswers> save(ProfileSetupAnswers profile) async {
    var consentUpdates = 0;
    if (profile.serverVersion != null) {
      final latest = await api.request('GET', '/api/v1/me/profile');
      if (latest['version'] != profile.serverVersion) {
        throw const ApiFailure(
          'Profil berubah. Muat ulang sebelum menyimpan.',
          status: 409,
        );
      }
    }
    // Resolve every restriction before sending a mutation: never silently omit an allergy.
    if (ingredients.isEmpty) {
      await ensureConsent(profile.aiEnabled);
      consentUpdates++;
      await loadIngredients();
    }
    final diet = {
      'directive': dietCodes[profile.dietType] ?? 'none',
      'phase': phaseCodes[profile.dietPhase] ?? 'unknown',
      'allergies': _ids(profile.allergies),
      'avoided_ingredients': _ids(profile.avoidedIngredients),
      'tolerances': _ids(profile.tolerances),
      'portion_limits': [
        for (final entry in profile.portionLimits.entries)
          if (entry.value != null)
            {
              'ingredient_id': _ids([entry.key]).single,
              'quantity': entry.value,
              'unit': 'porsi',
            },
      ],
      'budget_rupiah': profile.budget == null
          ? null
          : int.tryParse(profile.budget!.replaceAll(RegExp(r'[^0-9]'), '')),
      'spicy': spicyCodes[profile.spicy],
      'preferences': profile.preferences,
    };
    await ensureConsent(profile.aiEnabled);
    consentUpdates++;
    final current = await api.request('GET', '/api/v1/me/profile');
    if (profile.serverVersion != null &&
        current['version'] != profile.serverVersion! + consentUpdates) {
      throw const ApiFailure(
        'Profil berubah. Muat ulang sebelum menyimpan.',
        status: 409,
      );
    }
    rawProfile = await api.request(
      'PATCH',
      '/api/v1/me/profile',
      body: {
        'version': current['version'],
        'display_name': profile.displayName,
        'age_band': ageCodes[profile.ageBand],
        'diagnosis_reported': answerCodes[profile.diagnosis],
        'clinician_guidance': answerCodes[profile.clinicianGuidance],
        'timezone': 'Asia/Jakarta',
        'diet': diet,
        'save_photos': profile.savePhotos,
      },
    );
    assessment = await api.request('GET', '/api/v1/me/assessment');
    final answers = <String, dynamic>{};
    for (final (index, key) in [
      'severe_active',
      'bleeding',
      'weight_loss',
      'anemia',
      'family_history',
    ].indexed) {
      if (index < profile.redFlags.length && profile.redFlags[index] != null) {
        answers[key] = answerCodes[profile.redFlags[index]];
      }
    }
    if (answers.containsKey('bleeding')) {
      answers['bleeding_active'] = answers['bleeding'];
    }
    for (final entry in {0: 'q1', 3: 'q4', 4: 'q5', 5: 'q6'}.entries) {
      if (entry.key < profile.pattern.length &&
          profile.pattern[entry.key] != null) {
        answers[entry.value] = answerCodes[profile.pattern[entry.key]];
      }
    }
    if (profile.pattern.length > 1 && profile.pattern[1] != null) {
      final value = profile.pattern[1]!;
      final numeric = RegExp(r'^(\d+) hari$').firstMatch(value);
      answers['q2_days'] = numeric == null ? null : int.parse(numeric[1]!);
      answers['q2_band'] = numeric != null
          ? null
          : const {
                  'Kurang dari 1 hari': 'under_1',
                  '1–2 hari': '1_2',
                  '3–4 hari': '3_4',
                  '5 hari atau lebih': '5_plus',
                  'Tidak tahu': 'unknown',
                }[value] ??
                'unknown';
    }
    if (profile.pattern.length > 2 && profile.pattern[2] != null) {
      final value = profile.pattern[2]!;
      final numeric = RegExp(r'^(\d+) bulan$').firstMatch(value);
      answers['q3_months'] = numeric == null ? null : int.parse(numeric[1]!);
      answers['q3_band'] = numeric != null
          ? null
          : const {
                  'Kurang dari 3 bulan': 'under_3',
                  '3–5 bulan': '3_5',
                  '6–12 bulan': '6_12',
                  'Lebih dari 12 bulan': 'over_12',
                  'Tidak tahu': 'unknown',
                }[value] ??
                'unknown';
    }
    if (answers.isNotEmpty) {
      assessment = await api.request(
        'PATCH',
        '/api/v1/me/assessment',
        body: {'version': assessment['version'], 'answers': answers},
      );
      await api.request('POST', '/api/v1/me/assessment/evaluate');
      rawProfile = await api.request('GET', '/api/v1/me/profile');
    }
    return fromServer(profile.email);
  }

  Future<ScreeningAssessment> assess(ScreeningAnswers input) async {
    try {
      // Consent has been selected on the preceding screen, before screening starts.
      final current = await api.request('GET', '/api/v1/me/profile');
      rawProfile = await api.request(
        'PATCH',
        '/api/v1/me/profile',
        body: {
          'version': current['version'],
          'age_band': input.ageBand,
          'diagnosis_reported': input.diagnosis,
          'clinician_guidance': input.clinicianGuidance,
        },
      );
      final previous = await api.request('GET', '/api/v1/me/assessment');
      assessment = await api.request(
        'PATCH',
        '/api/v1/me/assessment',
        body: {
          'version': previous['version'],
          'answers': {
            'severe_active': input.severeActive,
            'bleeding': input.bleeding,
            'bleeding_active': input.bleedingActive,
            'weight_loss': input.weightLoss,
            'anemia': input.anemia,
            'family_history': input.familyHistory,
            'q1': input.q1,
            'q2_days': null,
            'q2_band': input.q2FrequencyBand,
            'q3_months': null,
            'q3_band': input.q3DurationBand,
            'q4': input.q4,
            'q5': input.q5,
            'q6': input.q6,
          },
        },
      );
      final result = await api.request(
        'POST',
        '/api/v1/me/assessment/evaluate',
      );
      const routes = {
        'out_of_scope': ScreeningRoute.outOfScope,
        'help': ScreeningRoute.help,
        'consultation': ScreeningRoute.consultation,
        'complete_answers': ScreeningRoute.completeAnswers,
        'diet_support': ScreeningRoute.dietSupport,
        'logging_only': ScreeningRoute.loggingOnly,
      };
      return ScreeningAssessment(
        route: routes[result['route']] ?? ScreeningRoute.loggingOnly,
        headline: switch (result['pattern_status']) {
          'matches_demo' => 'Polanya cocok dengan kriteria IBS',
          'does_not_match_demo' => 'Belum cocok dengan kriteria IBS',
          _ => 'Jawabannya belum cukup',
        },
        criteria: (result['criteria'] as List? ?? [null, null, null, null])
            .cast<bool?>(),
        reasons: (result['reasons'] as List? ?? []).cast<String>(),
      );
    } on ApiFailure catch (e) {
      throw ScreeningAssessmentException(e.message);
    }
  }
}
