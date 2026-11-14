import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/aibs_tokens.dart';
import '../shared/widgets/koala.dart';
import '../shared/widgets/step_progress.dart';
import '../widgets/aibs_widgets.dart';

enum ScreeningRoute {
  outOfScope,
  help,
  consultation,
  completeAnswers,
  dietSupport,
  loggingOnly,
}

class ScreeningAnswers {
  const ScreeningAnswers({
    required this.ageBand,
    required this.diagnosis,
    required this.clinicianGuidance,
    required this.severeActive,
    required this.bleeding,
    required this.bleedingActive,
    required this.weightLoss,
    required this.anemia,
    required this.familyHistory,
    required this.q1,
    required this.q2FrequencyBand,
    required this.q3DurationBand,
    required this.q4,
    required this.q5,
    required this.q6,
  });

  final String ageBand;
  final String diagnosis;
  final String clinicianGuidance;
  final String severeActive;
  final String bleeding;
  final String bleedingActive;
  final String weightLoss;
  final String anemia;
  final String familyHistory;
  final String q1;
  final String q2FrequencyBand;
  final String q3DurationBand;
  final String q4;
  final String q5;
  final String q6;
}

class ScreeningAssessment {
  const ScreeningAssessment({
    required this.route,
    required this.headline,
    this.criteria = const [],
    this.reasons = const [],
    this.missingFields = const [],
  });

  final ScreeningRoute route;
  final String headline;
  final List<bool?> criteria;
  final List<String> reasons;
  final List<String> missingFields;
}

class ScreeningAssessmentException implements Exception {
  const ScreeningAssessmentException(this.message);

  final String message;
}

typedef ScreeningAssessor = Future<ScreeningAssessment> Function(
  ScreeningAnswers answers,
);

class ProfileSetupAnswers {
  ProfileSetupAnswers({
    required this.displayName,
    required this.email,
    required this.ageBand,
    required this.diagnosis,
    required this.clinicianGuidance,
    required List<String?> redFlags,
    required List<String?> pattern,
    required this.dietType,
    required this.dietPhase,
    required List<String> avoidedIngredients,
    required Map<String, int?> portionLimits,
    required List<String> allergies,
    required List<String> tolerances,
    required this.budget,
    required this.spicy,
    required List<String> preferences,
    this.aiEnabled = true,
    this.savePhotos = false,
    this.serverVersion,
    this.bleedingActive,
  }) : redFlags = List.unmodifiable(redFlags),
       pattern = List.unmodifiable(pattern),
       avoidedIngredients = List.unmodifiable(avoidedIngredients),
       portionLimits = Map.unmodifiable(portionLimits),
       allergies = List.unmodifiable(allergies),
       tolerances = List.unmodifiable(tolerances),
       preferences = List.unmodifiable(preferences);

  final String displayName;
  final String email;
  final String? ageBand;
  final String? diagnosis;
  final String? clinicianGuidance;
  final List<String?> redFlags;
  final List<String?> pattern;
  final String? dietType;
  final String? dietPhase;
  final List<String> avoidedIngredients;
  final Map<String, int?> portionLimits;
  final List<String> allergies;
  final List<String> tolerances;
  final String? budget;
  final String? spicy;
  final List<String> preferences;
  final bool aiEnabled;
  final bool savePhotos;
  final int? serverVersion;
  final String? bleedingActive;

  ProfileSetupAnswers copyWithDietProfile({
    required String? dietType,
    required String? dietPhase,
    required List<String> avoidedIngredients,
    required Map<String, int?> portionLimits,
    bool? aiEnabled,
    bool? savePhotos,
  }) => ProfileSetupAnswers(
    displayName: displayName,
    email: email,
    ageBand: ageBand,
    diagnosis: diagnosis,
    clinicianGuidance: clinicianGuidance,
    redFlags: redFlags,
    pattern: pattern,
    dietType: dietType,
    dietPhase: dietPhase,
    avoidedIngredients: avoidedIngredients,
    portionLimits: portionLimits,
    allergies: allergies,
    tolerances: tolerances,
    budget: budget,
    spicy: spicy,
    preferences: preferences,
    aiEnabled: aiEnabled ?? this.aiEnabled,
    savePhotos: savePhotos ?? this.savePhotos,
    serverVersion: serverVersion,
    bleedingActive: bleedingActive,
  );
}

typedef ProfileSetupComplete = void Function(ProfileSetupAnswers answers);

enum _ProfileStep {
  age,
  diagnosis,
  clinicianGuidance,
  redFlags,
  pattern,
  ageScope,
  help,
  assessmentLoading,
  assessmentFailed,
  assessmentResult,
  dietType,
  fodmapPhase,
  avoidedIngredients,
  portionLimits,
  allergies,
  tolerances,
  budget,
  spicy,
  otherPreferences,
  review,
}

class ProfileSetupFlow extends StatefulWidget {
  const ProfileSetupFlow({
    required this.displayName,
    required this.email,
    required this.onComplete,
    required this.onBackToAccount,
    super.key,
    this.onAssess,
    this.aiEnabled = true,
    this.initialProgress = const {},
    this.onProgress,
    this.initialAnswers,
  });

  final String displayName;
  final String email;
  final ProfileSetupComplete onComplete;
  final VoidCallback onBackToAccount;
  final ScreeningAssessor? onAssess;
  final bool aiEnabled;
  final Map<String, dynamic> initialProgress;
  final Future<void> Function(Map<String, dynamic>)? onProgress;
  final ProfileSetupAnswers? initialAnswers;

  @override
  State<ProfileSetupFlow> createState() => _ProfileSetupFlowState();
}

class _ProfileSetupFlowState extends State<ProfileSetupFlow> {
  final _avoidController = TextEditingController();
  final _allergyController = TextEditingController();
  final _toleranceController = TextEditingController();
  final _customBudgetController = TextEditingController();
  final _redFlags = List<String?>.filled(5, null);
  final _patternAnswers = List<String?>.filled(6, null);
  final _avoidedIngredients = <String>{};
  final _allergies = <String>{};
  final _tolerances = <String>{};
  final _preferences = <String>{};
  final _portionLimits = <String, int?>{'Nasi': 1, 'Buah': 1, 'Roti': null};

  _ProfileStep _step = _ProfileStep.age;
  String? _ageBand;
  String? _diagnosis;
  String? _clinicianGuidance;
  String? _dietType;
  String? _dietPhase;
  String? _budget;
  String? _spicy;
  String? _formError;
  ScreeningAssessment? _assessment;
  String? _assessmentError;
  int _redFlagIndex = 0;
  int _patternIndex = 0;
  bool _returnToReview = false;
  bool _customBudgetMode = false;
  bool _showOtherAllergyField = false;
  bool _showToleranceField = false;
  int _assessmentRequestId = 0;
  String? _bleedingActive;
  String _progressSignature = '';
  Future<void> _progressSave = Future.value();
  bool _finishing = false;
  bool _progressFailed = false;

  Map<String, dynamic> get _snapshot => {
    'step': _step.name,
    'redFlagIndex': _redFlagIndex,
    'patternIndex': _patternIndex,
    'ageBand': _ageBand,
    'diagnosis': _diagnosis,
    'clinicianGuidance': _clinicianGuidance,
    'redFlags': _redFlags,
    'pattern': _patternAnswers,
    'bleedingActive': _bleedingActive,
    'dietType': _dietType,
    'dietPhase': _dietPhase,
    'budget': _budget,
    'spicy': _spicy,
    'avoided': _avoidedIngredients.toList(),
    'allergies': _allergies.toList(),
    'tolerances': _tolerances.toList(),
    'preferences': _preferences.toList(),
    'portionLimits': _portionLimits,
    'ai': widget.aiEnabled,
  };

  @override
  void initState() {
    super.initState();
    final a = widget.initialAnswers;
    final Map<String, dynamic> p = widget.initialProgress.isNotEmpty
        ? widget.initialProgress
        : a == null
        ? <String, dynamic>{}
        : {
            'ageBand': a.ageBand,
            'diagnosis': a.diagnosis,
            'clinicianGuidance': a.clinicianGuidance,
            'redFlags': a.redFlags,
            'pattern': a.pattern,
            'bleedingActive': a.bleedingActive,
            'dietType': a.dietType,
            'dietPhase': a.dietPhase,
            'avoided': a.avoidedIngredients,
            'allergies': a.allergies,
            'tolerances': a.tolerances,
            'preferences': a.preferences,
            'portionLimits': a.portionLimits,
            'budget': a.budget,
            'spicy': a.spicy,
          };
    if (p.isEmpty) return;
    _ageBand = p['ageBand'];
    _diagnosis = p['diagnosis'];
    _clinicianGuidance = p['clinicianGuidance'];
    _bleedingActive = p['bleedingActive'];
    _dietType = p['dietType'];
    _dietPhase = p['dietPhase'];
    _budget = p['budget'];
    _spicy = p['spicy'];
    for (final (key, target) in [
      ('redFlags', _redFlags),
      ('pattern', _patternAnswers),
    ]) {
      final values = p[key] as List? ?? [];
      for (var i = 0; i < values.length && i < target.length; i++) {
        target[i] = values[i] as String?;
      }
    }
    for (final (key, target) in [
      ('avoided', _avoidedIngredients),
      ('allergies', _allergies),
      ('tolerances', _tolerances),
      ('preferences', _preferences),
    ]) {
      target.addAll((p[key] as List? ?? []).cast<String>());
    }
    if (p['portionLimits'] is Map) {
      _portionLimits
        ..clear()
        ..addAll(Map<String, int?>.from(p['portionLimits']));
    }
    _redFlagIndex = (p['redFlagIndex'] as int? ?? 0).clamp(0, 4);
    _patternIndex = (p['patternIndex'] as int? ?? 0).clamp(0, 5);
    _step =
        _ProfileStep.values.where((s) => s.name == p['step']).firstOrNull ??
        _ProfileStep.age;
    if ([
      _ProfileStep.assessmentLoading,
      _ProfileStep.assessmentResult,
      _ProfileStep.assessmentFailed,
    ].contains(_step)) {
      _step = _ProfileStep.pattern;
    }
  }

  void _persistProgress() {
    if (widget.onProgress == null ||
        _finishing ||
        _progressFailed ||
        _step == _ProfileStep.assessmentLoading) {
      return;
    }
    final signature = jsonEncode(_snapshot);
    if (signature == _progressSignature) return;
    _progressSignature = signature;
    final snapshot = jsonDecode(signature) as Map<String, dynamic>;
    _progressSave = _progressSave
        .then((_) => widget.onProgress!(snapshot))
        .catchError((Object error) {
          if (mounted) {
            setState(() {
              _progressFailed = true;
              _formError = 'Progres belum tersimpan. Coba lagi sebelum keluar.';
            });
          }
        });
  }

  static const _fodmapDefaults = {
    'Bawang putih',
    'Bawang bombay',
    'Susu sapi',
    'Gandum',
  };
  static const _allergyOptions = [
    'Udang',
    'Kacang tanah',
    'Telur',
    'Susu',
    'Ikan',
    'Kedelai',
    'Kerang',
  ];
  static const _toleranceOptions = [
    'Santan',
    'Gorengan',
    'Kopi',
    'Soda',
    'Makanan berminyak',
  ];

  static const _redFlagQuestions = [
    'Apakah saat ini kamu mengalami nyeri perut sangat berat atau cepat memburuk, pingsan, atau sulit minum?',
    'Apakah ada darah saat BAB atau feses hitam seperti ter, dan apakah sedang terjadi?',
    'Apakah berat badan turun tanpa disengaja?',
    'Apakah dokter pernah menyebut anemia yang belum jelas penyebabnya?',
    'Apakah keluarga dekat memiliki riwayat kanker usus, IBD, atau celiac?',
  ];

  static const _patternQuestions = [
    'Dalam tiga bulan terakhir, apakah nyeri atau rasa tidak nyaman di perut muncul berulang dan tidak terus-menerus?',
    'Dalam periode itu, rata-rata berapa hari per bulan keluhan terasa?',
    'Sudah berapa lama sejak keluhan pertama muncul?',
    'Apakah keluhan berkaitan dengan BAB, misalnya berubah saat atau setelah BAB?',
    'Apakah frekuensi BAB berubah saat pola keluhan muncul?',
    'Apakah bentuk atau konsistensi feses berubah saat pola keluhan muncul?',
  ];

  static const _yesNoUnknown = ['Ya', 'Tidak', 'Tidak tahu'];
  static const _frequencyOptions = [
    'Kurang dari 1 hari',
    '1–2 hari',
    '3–4 hari',
    '5 hari atau lebih',
    'Tidak tahu',
  ];
  static const _durationOptions = [
    'Kurang dari 3 bulan',
    '3–5 bulan',
    '6–12 bulan',
    'Lebih dari 12 bulan',
    'Tidak tahu',
  ];

  @override
  void dispose() {
    _avoidController.dispose();
    _allergyController.dispose();
    _toleranceController.dispose();
    _customBudgetController.dispose();
    super.dispose();
  }

  int? get _progress => switch (_step) {
    _ProfileStep.age => 1,
    _ProfileStep.diagnosis => 2,
    _ProfileStep.clinicianGuidance => 3,
    _ProfileStep.redFlags => 4,
    _ProfileStep.pattern => 5,
    _ProfileStep.dietType => 6,
    _ProfileStep.fodmapPhase => 7,
    _ProfileStep.avoidedIngredients => 8,
    _ProfileStep.portionLimits => 9,
    _ProfileStep.allergies => 10,
    _ProfileStep.tolerances => 11,
    _ProfileStep.budget => 12,
    _ProfileStep.spicy => 13,
    _ProfileStep.otherPreferences => 14,
    _ => null,
  };

  bool get _canEditDiet => _diagnosis == 'Ya' || _clinicianGuidance == 'Ya';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _persistProgress();
    });
    return Scaffold(
      backgroundColor: AibsColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: AibsMotion.page,
                child: SingleChildScrollView(
                  key: ValueKey('$_step-$_redFlagIndex-$_patternIndex'),
                  padding: const EdgeInsets.fromLTRB(
                    AibsSpace.s20,
                    AibsSpace.s24,
                    AibsSpace.s20,
                    AibsSpace.s24,
                  ),
                  child: _buildContent(),
                ),
              ),
            ),
            if (_formError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AibsSpace.s20,
                  0,
                  AibsSpace.s20,
                  AibsSpace.s8,
                ),
                child: Text(
                  _formError!,
                  style: AibsType.caption.copyWith(color: AibsColors.badInk),
                ),
              ),
            _buildActions(),
            if (_progressFailed)
              TextButton(
                onPressed: () {
                  setState(() {
                    _progressFailed = false;
                    _progressSignature = '';
                    _formError = null;
                  });
                },
                child: const Text('Coba simpan progres lagi'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final progress = _progress;
    final rightAction = switch (_step) {
      _ProfileStep.age ||
      _ProfileStep.diagnosis ||
      _ProfileStep.clinicianGuidance ||
      _ProfileStep.redFlags ||
      _ProfileStep.pattern => 'Nanti',
      _ProfileStep.portionLimits ||
      _ProfileStep.tolerances ||
      _ProfileStep.otherPreferences => 'Lewati',
      _ => null,
    };

    return Padding(
      padding: AibsSpace.topBar,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
          ),
          if (progress != null) ...[
            const SizedBox(width: AibsSpace.s8),
            Expanded(child: StepProgress(step: progress)),
          ] else
            const Spacer(),
          if (rightAction != null)
            TextButton(
              onPressed: rightAction == 'Nanti' ? _finish : _skipOptional,
              child: Text(rightAction),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() => switch (_step) {
    _ProfileStep.age => _singleChoice(
      title: 'Berapa usia kamu?',
      options: const ['Di bawah 18', '18–29', '30–39', '40–49', '50 ke atas'],
      onSelected: _selectAge,
    ),
    _ProfileStep.diagnosis => _singleChoice(
      title: 'Apakah dokter pernah mendiagnosis kamu dengan IBS?',
      options: _yesNoUnknown,
      onSelected: (answer) => _selectAndAdvance(
        _ProfileStep.clinicianGuidance,
        () => _diagnosis = answer,
      ),
    ),
    _ProfileStep.clinicianGuidance => _singleChoice(
      title: 'Apakah kamu sedang mengikuti arahan makan dari dokter atau ahli gizi?',
      options: const ['Ya', 'Tidak'],
      onSelected: (answer) => _selectAndAdvance(
        _ProfileStep.redFlags,
        () => _clinicianGuidance = answer,
      ),
    ),
    _ProfileStep.redFlags => _buildRedFlags(),
    _ProfileStep.pattern => _buildPattern(),
    _ProfileStep.ageScope => _buildAgeScope(),
    _ProfileStep.help => _buildHelp(),
    _ProfileStep.assessmentLoading => _buildAssessmentLoading(),
    _ProfileStep.assessmentFailed => _buildAssessmentFailed(),
    _ProfileStep.assessmentResult => _buildAssessmentResult(),
    _ProfileStep.dietType => _buildDietType(),
    _ProfileStep.fodmapPhase => _buildFodmapPhase(),
    _ProfileStep.avoidedIngredients => _buildAvoidedIngredients(),
    _ProfileStep.portionLimits => _buildPortionLimits(),
    _ProfileStep.allergies => _buildAllergies(),
    _ProfileStep.tolerances => _buildTolerances(),
    _ProfileStep.budget => _buildBudget(),
    _ProfileStep.spicy => _singleChoice(
      title: 'Suka pedas?',
      options: const ['Nggak pedas', 'Sedikit', 'Sedang', 'Pedas banget'],
      onSelected: (answer) =>
          _selectAndAdvance(_ProfileStep.otherPreferences, () {
            _spicy = answer;
          }),
    ),
    _ProfileStep.otherPreferences => _buildOtherPreferences(),
    _ProfileStep.review => _buildReview(),
  };

  Widget _singleChoice({
    required String title,
    required List<String> options,
    required ValueChanged<String> onSelected,
    String? counter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (counter != null) ...[
          Text(
            counter,
            style: AibsType.label.copyWith(color: AibsColors.primaryStrong),
          ),
          const SizedBox(height: AibsSpace.s8),
        ],
        Text(title, style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        for (final option in options) ...[
          _OptionCard(label: option, onTap: () => onSelected(option)),
          const SizedBox(height: AibsSpace.s10),
        ],
      ],
    );
  }

  Widget _buildRedFlags() {
    if (_redFlagIndex == 1 && _redFlags[1] == 'Ya' && _bleedingActive == null) {
      return _singleChoice(
        title: 'Apakah darah saat BAB atau feses hitam sedang terjadi?',
        options: _yesNoUnknown,
        onSelected: (answer) {
          _bleedingActive = answer;
          if (answer == 'Ya') {
            setState(() => _step = _ProfileStep.help);
          } else {
            _answerRedFlag('Ya');
          }
        },
      );
    }
    final index = _redFlagIndex;
    return _singleChoice(
      title: _redFlagQuestions[index],
      counter: '${index + 1} dari 5',
      options: _yesNoUnknown,
      onSelected: _answerRedFlag,
    );
  }

  Widget _buildPattern() {
    final index = _patternIndex;
    return _singleChoice(
      title: _patternQuestions[index],
      counter: '${index + 1} dari 6',
      options: switch (index) {
        1 => _frequencyOptions,
        2 => _durationOptions,
        _ => _yesNoUnknown,
      },
      onSelected: _answerPattern,
    );
  }

  Widget _buildAgeScope() {
    return Column(
      children: [
        const Koala(KoalaMood.mikir, size: AibsSize.koalaScope),
        const SizedBox(height: AibsSpace.s24),
        Text(
          'AIBS dibuat untuk usia 18+',
          style: AibsType.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AibsSpace.s12),
        Text(
          'Ajak orang tua atau dokter buat bantu atur makanmu.',
          style: AibsType.body.copyWith(color: AibsColors.inkMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHelp() {
    const steps = [
      ('Sakit hebat atau nggak reda?', 'Langsung ke IGD terdekat'),
      ('Hubungi dokter atau faskes', null),
      ('Bawa ringkasan keluhanmu', null),
    ];
    return Column(
      children: [
        const Koala(KoalaMood.khawatir, size: AibsSize.koalaHelp),
        const SizedBox(height: AibsSpace.s16),
        Text(
          'Periksa ke dokter dulu, ya',
          style: AibsType.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AibsSpace.s20),
        AibsCard(
          child: Column(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                if (index > 0) const Divider(height: AibsSpace.s20),
                _HelpStep(
                  number: index + 1,
                  title: steps[index].$1,
                  detail: steps[index].$2,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AibsSpace.s12),
        Text(
          'Teks ini perlu ditinjau tenaga medis.',
          style: AibsType.micro.copyWith(color: AibsColors.inkMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAssessmentLoading() {
    return Column(
      children: [
        const Koala(KoalaMood.mikir, size: AibsSize.koalaHelp),
        const SizedBox(height: AibsSpace.s20),
        Text('Lagi cek jawabanmu', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildAssessmentFailed() {
    return Column(
      children: [
        const Koala(KoalaMood.mikir, size: AibsSize.koalaHelp),
        const SizedBox(height: AibsSpace.s20),
        Text(
          'Pengecekan belum selesai',
          style: AibsType.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AibsSpace.s12),
        Text(
          _assessmentError ?? 'Coba lagi nanti.',
          style: AibsType.body.copyWith(color: AibsColors.inkMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAssessmentResult() {
    final assessment = _assessment;
    final criteria =
        assessment?.criteria ?? const <bool?>[null, null, null, null];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VerdictCard(
          mood: assessment?.route == ScreeningRoute.consultation
              ? KoalaMood.mikir
              : KoalaMood.senang,
          label: 'Hasil pengecekan awal',
          headline:
              assessment?.headline ?? 'Hasil pengecekan awal belum tersedia',
          detail: assessment?.reasons.isNotEmpty == true
              ? assessment!.reasons.first
              : null,
          gradient: AibsGradients.hero,
          koalaSize: AibsSize.verdictKoala,
        ),
        const SizedBox(height: AibsSpace.s20),
        AibsCard(
          child: Column(
            children: [
              _criterionRow('Sakit perut berulang', criteria, 0),
              const Divider(height: AibsSpace.s20),
              _criterionRow('3+ hari per bulan', criteria, 1),
              const Divider(height: AibsSpace.s20),
              _criterionRow('Sudah 6 bulan lebih', criteria, 2),
              const Divider(height: AibsSpace.s20),
              _criterionRow('Berhubungan dengan BAB · 2 dari 3', criteria, 3),
            ],
          ),
        ),
        const SizedBox(height: AibsSpace.s12),
        Text(
          'Bukan diagnosis. Pastikan ke dokter.',
          style: AibsType.micro.copyWith(color: AibsColors.inkMuted),
        ),
        const SizedBox(height: AibsSpace.s8),
        TextButton(
          onPressed: () => setState(() {
            _patternIndex = 0;
            _step = _ProfileStep.pattern;
          }),
          child: const Text('Ubah jawaban'),
        ),
        if (assessment?.route == ScreeningRoute.consultation)
          Padding(
            padding: const EdgeInsets.only(top: AibsSpace.s8),
            child: Text(
              'Bawa jawaban ini saat konsultasi.',
              style: AibsType.caption.copyWith(color: AibsColors.inkMuted),
            ),
          ),
        const SizedBox(height: AibsSpace.s12),
      ],
    );
  }

  Widget _criterionRow(String label, List<bool?> criteria, int index) {
    final value = index < criteria.length ? criteria[index] : null;
    final color = value == true ? AibsColors.primary : AibsColors.unknownSoft;
    return Row(
      children: [
        Container(
          width: AibsSize.criterionDot,
          height: AibsSize.criterionDot,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              value == true ? '✓' : '–',
              style: AibsType.caption.copyWith(
                color: value == true
                    ? AibsColors.onPrimary
                    : AibsColors.inkMuted,
              ),
            ),
          ),
        ),
        const SizedBox(width: AibsSpace.s12),
        Expanded(child: Text(label, style: AibsType.bodyStrong)),
      ],
    );
  }

  Widget _buildDietType() {
    return _singleChoice(
      title: 'Arahan makan apa yang kamu ikuti?',
      options: const [
        'Low FODMAP',
        'Rendah lemak',
        'Tinggi serat',
        'Belum ada arahan',
        'Lainnya',
      ],
      onSelected: (answer) {
        final wasLowFodmap = _dietType == 'Low FODMAP';
        final isLowFodmap = answer == 'Low FODMAP';
        _selectAndAdvance(
          isLowFodmap
              ? _ProfileStep.fodmapPhase
              : _ProfileStep.avoidedIngredients,
          () {
            _dietType = answer;
            if (isLowFodmap) {
              if (!wasLowFodmap) {
                _avoidedIngredients.addAll(_fodmapDefaults);
              }
            } else if (wasLowFodmap) {
              _avoidedIngredients.removeAll(_fodmapDefaults);
              _dietPhase = null;
            }
          },
        );
      },
    );
  }

  Widget _buildFodmapPhase() {
    const phases = [
      ('Eliminasi', 'Menghindari semua FODMAP tinggi'),
      ('Reintroduksi', 'Mencoba lagi satu per satu'),
      ('Personalisasi', 'Sudah tahu yang cocok'),
      ('Belum tahu', null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Low FODMAP fase apa?', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        for (final phase in phases) ...[
          _OptionCard(
            label: phase.$1,
            detail: phase.$2,
            onTap: () => _selectAndAdvance(
              _ProfileStep.avoidedIngredients,
              () => _dietPhase = phase.$1,
            ),
          ),
          const SizedBox(height: AibsSpace.s10),
        ],
      ],
    );
  }

  Widget _buildAvoidedIngredients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bahan apa yang dihindari?', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        _addTextField(
          controller: _avoidController,
          hint: 'Tambah bahan',
          tooltip: 'Tambah bahan',
          onAdd: _addAvoidedIngredient,
        ),
        const SizedBox(height: AibsSpace.s12),
        Wrap(
          spacing: AibsSpace.s8,
          runSpacing: AibsSpace.s8,
          children: [
            for (final ingredient in {
              ..._fodmapDefaults.where((_) => _dietType == 'Low FODMAP'),
              ..._avoidedIngredients,
            })
              AibsChoiceChip(
                label: ingredient,
                selected: _avoidedIngredients.contains(ingredient),
                onTap: () => setState(() {
                  if (!_avoidedIngredients.add(ingredient)) {
                    _avoidedIngredients.remove(ingredient);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortionLimits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ada batas porsi?', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        for (final ingredient in _portionLimits.keys) ...[
          AibsCard(
            child: Row(
              children: [
                Expanded(child: Text(ingredient, style: AibsType.bodyStrong)),
                IconButton(
                  tooltip: 'Kurangi $ingredient',
                  onPressed: () => _changePortion(ingredient, -1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  (_portionLimits[ingredient] ?? 0) == 0
                      ? 'Tidak ada'
                      : '${_portionLimits[ingredient]} porsi',
                  style: AibsType.caption,
                ),
                IconButton(
                  tooltip: 'Tambah $ingredient',
                  onPressed: () => _changePortion(ingredient, 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: AibsSpace.s10),
        ],
      ],
    );
  }

  Widget _buildAllergies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Punya alergi makanan?', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        Wrap(
          spacing: AibsSpace.s8,
          runSpacing: AibsSpace.s8,
          children: [
            for (final option in _allergyOptions)
              AibsChoiceChip(
                label: option,
                selected: _allergies.contains(option),
                onTap: () => _toggle(_allergies, option),
              ),
            AibsChoiceChip(
              label: 'Lainnya',
              selected: _showOtherAllergyField,
              onTap: () => setState(
                () => _showOtherAllergyField = !_showOtherAllergyField,
              ),
            ),
          ],
        ),
        if (_showOtherAllergyField) ...[
          const SizedBox(height: AibsSpace.s20),
          _addTextField(
            controller: _allergyController,
            hint: 'Alergi lain',
            tooltip: 'Tambah alergi',
            onAdd: _addAllergy,
          ),
        ],
        if (_allergies.isNotEmpty) ...[
          const SizedBox(height: AibsSpace.s12),
          _selectedChips(_allergies.difference(_allergyOptions.toSet())),
        ],
      ],
    );
  }

  Widget _buildTolerances() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ada yang bikin perutmu nggak nyaman?', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        Wrap(
          spacing: AibsSpace.s8,
          runSpacing: AibsSpace.s8,
          children: [
            for (final option in _toleranceOptions)
              AibsChoiceChip(
                label: option,
                selected: _tolerances.contains(option),
                onTap: () => _toggle(_tolerances, option),
              ),
            AibsChoiceChip(
              label: 'Tambah',
              selected: _showToleranceField,
              onTap: () =>
                  setState(() => _showToleranceField = !_showToleranceField),
            ),
          ],
        ),
        if (_showToleranceField) ...[
          const SizedBox(height: AibsSpace.s20),
          _addTextField(
            controller: _toleranceController,
            hint: 'Tambah bahan',
            tooltip: 'Tambah bahan',
            onAdd: _addTolerance,
          ),
        ],
        if (_tolerances.isNotEmpty) ...[
          const SizedBox(height: AibsSpace.s12),
          _selectedChips(_tolerances.difference(_toleranceOptions.toSet())),
        ],
      ],
    );
  }

  Widget _buildBudget() {
    const options = ['Rp15.000', 'Rp25.000', 'Rp35.000', 'Rp50.000+'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget sekali makan?', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        for (final option in options) ...[
          _OptionCard(
            label: option,
            selected: _budget == option,
            onTap: () => _selectAndAdvance(_ProfileStep.spicy, () {
              _budget = option;
              _customBudgetMode = false;
            }),
          ),
          const SizedBox(height: AibsSpace.s10),
        ],
        _OptionCard(
          label: 'Ketik sendiri',
          selected: _customBudgetMode,
          onTap: () => setState(() {
            _customBudgetMode = true;
            _formError = null;
          }),
        ),
        if (_customBudgetMode) ...[
          const SizedBox(height: AibsSpace.s12),
          TextField(
            controller: _customBudgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Budget dalam rupiah',
              prefixText: 'Rp ',
            ),
            onChanged: (_) => setState(() => _formError = null),
          ),
        ],
      ],
    );
  }

  Widget _buildOtherPreferences() {
    const options = [
      'Halal',
      'Vegetarian',
      'Tanpa daging merah',
      'Masak ≤ 15 menit',
      'Lebih suka beli',
      'Lebih suka masak',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ada preferensi lain?', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        Wrap(
          spacing: AibsSpace.s8,
          runSpacing: AibsSpace.s8,
          children: [
            for (final option in options)
              AibsChoiceChip(
                label: option,
                selected: _preferences.contains(option),
                onTap: () => _toggle(_preferences, option),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Udah bener?', style: AibsType.title),
        const SizedBox(height: AibsSpace.s20),
        AibsCard(
          padding: AibsSpace.s8,
          child: Column(
            children: [
              _reviewRow('Arahan', _dietSummary, _ProfileStep.dietType),
              _reviewRow(
                'Dihindari',
                _listSummary(_avoidedIngredients),
                _ProfileStep.avoidedIngredients,
              ),
              _reviewRow(
                'Batas porsi',
                _portionSummary,
                _ProfileStep.portionLimits,
              ),
              _reviewRow(
                'Alergi',
                _listSummary(_allergies, empty: 'Nggak ada'),
                _ProfileStep.allergies,
              ),
              _reviewRow(
                'Bikin nggak nyaman',
                _listSummary(_tolerances, empty: 'Belum dipilih'),
                _ProfileStep.tolerances,
              ),
              _reviewRow(
                'Budget',
                _budget ?? 'Belum dipilih',
                _ProfileStep.budget,
              ),
              _reviewRow(
                'Pedas',
                _spicy ?? 'Belum dipilih',
                _ProfileStep.spicy,
              ),
              _reviewRow(
                'Lainnya',
                _listSummary(_preferences, empty: 'Belum dipilih'),
                _ProfileStep.otherPreferences,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String category, String value, _ProfileStep editStep) {
    return InkWell(
      onTap: () => _openReviewEdit(editStep),
      borderRadius: BorderRadius.circular(AibsRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AibsSpace.s8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: AibsType.small.copyWith(color: AibsColors.inkMuted),
                  ),
                  const SizedBox(height: AibsSpace.s2),
                  Text(value, style: AibsType.bodyStrong),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
          ],
        ),
      ),
    );
  }

  Widget _addTextField({
    required TextEditingController controller,
    required String hint,
    required String tooltip,
    required VoidCallback onAdd,
  }) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: IconButton(
          tooltip: tooltip,
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
      ),
      onSubmitted: (_) => onAdd(),
    );
  }

  Widget _selectedChips(Set<String> values) {
    return Wrap(
      spacing: AibsSpace.s8,
      runSpacing: AibsSpace.s8,
      children: [
        for (final value in values)
          InputChip(
            label: Text(value),
            onDeleted: () => setState(() => values.remove(value)),
          ),
      ],
    );
  }

  Widget _buildActions() {
    final padding = AibsSpace.bottomActions;
    final actions = switch (_step) {
      _ProfileStep.ageScope => [
        TextButton(
          onPressed: () => setState(() => _step = _ProfileStep.age),
          child: const Text('Ubah usia'),
        ),
      ],
      _ProfileStep.help => [
        AibsPrimaryButton(label: 'Telepon 119', onPressed: _callEmergency),
        const SizedBox(height: AibsSpace.s8),
        AibsSecondaryButton(
          label: 'Lihat ringkasan keluhan',
          onPressed: _showAnswersSummary,
        ),
      ],
      _ProfileStep.assessmentFailed => [
        AibsPrimaryButton(label: 'Coba lagi', onPressed: _submitAssessment),
      ],
      _ProfileStep.assessmentResult => _assessmentActions(),
      _ProfileStep.avoidedIngredients ||
      _ProfileStep.portionLimits ||
      _ProfileStep.allergies ||
      _ProfileStep.tolerances ||
      _ProfileStep.otherPreferences => [
        AibsPrimaryButton(label: 'Lanjut', onPressed: _next),
        if (_step == _ProfileStep.allergies) ...[
          const SizedBox(height: AibsSpace.s8),
          TextButton(
            onPressed: () => setState(() {
              _allergies.clear();
              _showOtherAllergyField = false;
              _advanceTo(_ProfileStep.tolerances);
            }),
            child: const Text('Nggak ada alergi'),
          ),
        ],
      ],
      _ProfileStep.budget when _customBudgetMode => [
        AibsPrimaryButton(label: 'Lanjut', onPressed: _next),
      ],
      _ProfileStep.review => [
        AibsPrimaryButton(label: 'Simpan profil', onPressed: _finish),
      ],
      _ => const <Widget>[],
    };

    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Column(mainAxisSize: MainAxisSize.min, children: actions),
    );
  }

  List<Widget> _assessmentActions() {
    final assessment = _assessment;
    if (assessment?.route == ScreeningRoute.completeAnswers) {
      return [
        AibsPrimaryButton(
          label: 'Lengkapi jawaban',
          onPressed: () => setState(() {
            final fields = assessment!.missingFields;
            if (fields.contains('age_band')) {
              _step = _ProfileStep.age;
            } else if (fields.contains('diagnosis_reported')) {
              _step = _ProfileStep.diagnosis;
            } else if (fields.contains('clinician_guidance')) {
              _step = _ProfileStep.clinicianGuidance;
            } else {
              final index = [
                'severe_active',
                'bleeding',
                'weight_loss',
                'anemia',
                'family_history',
              ].indexWhere(fields.contains);
              if (index >= 0) {
                _redFlagIndex = index;
                _step = _ProfileStep.redFlags;
              } else {
                _patternIndex = 0;
                _step = _ProfileStep.pattern;
              }
            }
          }),
        ),
        const SizedBox(height: AibsSpace.s8),
        AibsSecondaryButton(label: 'Mulai catat aja', onPressed: _finish),
      ];
    }

    final canEditDiet = assessment?.route == ScreeningRoute.dietSupport;
    if (!canEditDiet) {
      return [AibsPrimaryButton(label: 'Mulai catat aja', onPressed: _finish)];
    }
    return [
      AibsPrimaryButton(
        label: 'Isi arahan diet',
        onPressed: () => setState(() => _step = _ProfileStep.dietType),
      ),
      const SizedBox(height: AibsSpace.s8),
      AibsSecondaryButton(label: 'Mulai catat aja', onPressed: _finish),
    ];
  }

  void _selectAge(String answer) {
    setState(() {
      _ageBand = answer;
      _step = answer == 'Di bawah 18'
          ? _ProfileStep.ageScope
          : _ProfileStep.diagnosis;
    });
  }

  void _selectAndAdvance(_ProfileStep next, VoidCallback update) {
    setState(() {
      update();
      _formError = null;
      _advanceTo(next);
    });
  }

  void _answerRedFlag(String answer) {
    if (_redFlagIndex == 1 && answer == 'Ya' && _bleedingActive == null) {
      setState(() {
        _redFlags[1] = answer;
      });
      return;
    }
    setState(() {
      _redFlags[_redFlagIndex] = answer;
      if (_redFlagIndex == 0 && answer == 'Ya') {
        _step = _ProfileStep.help;
      } else if (_redFlagIndex < _redFlags.length - 1) {
        _redFlagIndex++;
      } else {
        _patternIndex = 0;
        _step = _ProfileStep.pattern;
      }
    });
  }

  void _answerPattern(String answer) {
    final isLast = _patternIndex == _patternAnswers.length - 1;
    setState(() {
      _patternAnswers[_patternIndex] = answer;
      if (!isLast) _patternIndex++;
    });
    if (isLast) _submitAssessment();
  }

  Future<void> _submitAssessment() async {
    await _progressSave;
    final assessor = widget.onAssess;
    if (assessor == null) {
      setState(() {
        _assessment = ScreeningAssessment(
          route: _canEditDiet
              ? ScreeningRoute.dietSupport
              : ScreeningRoute.loggingOnly,
          headline: 'Hasil pengecekan awal belum tersedia',
        );
        _step = _ProfileStep.assessmentResult;
      });
      return;
    }

    setState(() {
      _assessmentError = null;
      _step = _ProfileStep.assessmentLoading;
    });
    final requestId = ++_assessmentRequestId;
    try {
      final result = await assessor(_screeningAnswers);
      if (!mounted || requestId != _assessmentRequestId) return;
      setState(() {
        _assessment = result;
        _step = switch (result.route) {
          ScreeningRoute.help => _ProfileStep.help,
          ScreeningRoute.outOfScope => _ProfileStep.ageScope,
          _ => _ProfileStep.assessmentResult,
        };
      });
    } on ScreeningAssessmentException catch (error) {
      if (!mounted || requestId != _assessmentRequestId) return;
      setState(() {
        _assessmentError = error.message;
        _step = _ProfileStep.assessmentFailed;
      });
    }
  }

  ScreeningAnswers get _screeningAnswers {
    return ScreeningAnswers(
      ageBand: switch (_ageBand) {
        '18–29' => '18_29',
        '30–39' => '30_39',
        '40–49' => '40_49',
        '50 ke atas' => '50_plus',
        _ => 'under_18',
      },
      diagnosis: _answerValue(_diagnosis),
      clinicianGuidance: _answerValue(_clinicianGuidance),
      severeActive: _answerValue(_redFlags[0]),
      bleeding: _answerValue(_redFlags[1]),
      bleedingActive: _redFlags[1] == 'Tidak'
          ? 'no'
          : _answerValue(_bleedingActive),
      weightLoss: _answerValue(_redFlags[2]),
      anemia: _answerValue(_redFlags[3]),
      familyHistory: _answerValue(_redFlags[4]),
      q1: _answerValue(_patternAnswers[0]),
      q2FrequencyBand: _frequencyValue(_patternAnswers[1] ?? 'Tidak tahu'),
      q3DurationBand: _durationValue(_patternAnswers[2] ?? 'Tidak tahu'),
      q4: _answerValue(_patternAnswers[3]),
      q5: _answerValue(_patternAnswers[4]),
      q6: _answerValue(_patternAnswers[5]),
    );
  }

  String _answerValue(String? answer) => switch (answer) {
    'Ya' => 'yes',
    'Tidak' => 'no',
    _ => 'unknown',
  };

  String _frequencyValue(String answer) => switch (answer) {
    'Kurang dari 1 hari' => 'under_1',
    '1–2 hari' => '1_2',
    '3–4 hari' => '3_4',
    '5 hari atau lebih' => '5_plus',
    _ => 'unknown',
  };

  String _durationValue(String answer) => switch (answer) {
    'Kurang dari 3 bulan' => 'under_3',
    '3–5 bulan' => '3_5',
    '6–12 bulan' => '6_12',
    'Lebih dari 12 bulan' => 'over_12',
    _ => 'unknown',
  };

  void _next() {
    if (_step == _ProfileStep.budget && _customBudgetMode) {
      final amount = int.tryParse(_customBudgetController.text.trim());
      if (amount == null || amount <= 0) {
        setState(() => _formError = 'Masukkan budget yang valid.');
        return;
      }
      _selectAndAdvance(_ProfileStep.spicy, () {
        _budget = 'Rp${_formatRupiah(amount)}';
      });
      return;
    }
    final next = switch (_step) {
      _ProfileStep.avoidedIngredients => _ProfileStep.portionLimits,
      _ProfileStep.portionLimits => _ProfileStep.allergies,
      _ProfileStep.allergies => _ProfileStep.tolerances,
      _ProfileStep.tolerances => _ProfileStep.budget,
      _ProfileStep.otherPreferences => _ProfileStep.review,
      _ => _step,
    };
    _selectAndAdvance(next, () {});
  }

  void _advanceTo(_ProfileStep next) {
    if (_returnToReview && next != _ProfileStep.fodmapPhase) {
      _step = _ProfileStep.review;
      _returnToReview = false;
    } else {
      _step = next;
    }
  }

  void _skipOptional() {
    final next = switch (_step) {
      _ProfileStep.portionLimits => _ProfileStep.allergies,
      _ProfileStep.tolerances => _ProfileStep.budget,
      _ProfileStep.otherPreferences => _ProfileStep.review,
      _ => _step,
    };
    setState(() {
      _formError = null;
      _advanceTo(next);
    });
  }

  void _back() {
    setState(() {
      _formError = null;
      if (_returnToReview &&
          _step != _ProfileStep.fodmapPhase &&
          _step != _ProfileStep.dietType) {
        _returnToReview = false;
        _step = _ProfileStep.review;
        return;
      }
      if (_returnToReview && _step == _ProfileStep.dietType) {
        _returnToReview = false;
        _step = _ProfileStep.review;
        return;
      }
      switch (_step) {
        case _ProfileStep.age:
          widget.onBackToAccount();
          break;
        case _ProfileStep.diagnosis:
          _step = _ProfileStep.age;
          break;
        case _ProfileStep.clinicianGuidance:
          _step = _ProfileStep.diagnosis;
          break;
        case _ProfileStep.redFlags:
          if (_redFlagIndex > 0) {
            _redFlagIndex--;
          } else {
            _step = _ProfileStep.clinicianGuidance;
          }
          break;
        case _ProfileStep.pattern:
          if (_patternIndex > 0) {
            _patternIndex--;
          } else {
            _redFlagIndex = _redFlags.length - 1;
            _step = _ProfileStep.redFlags;
          }
          break;
        case _ProfileStep.ageScope:
          _step = _ProfileStep.age;
          break;
        case _ProfileStep.help:
          _redFlagIndex = 0;
          _step = _ProfileStep.redFlags;
          break;
        case _ProfileStep.assessmentLoading:
        case _ProfileStep.assessmentFailed:
          if (_step == _ProfileStep.assessmentLoading) {
            _assessmentRequestId++;
          }
          _step = _ProfileStep.pattern;
          break;
        case _ProfileStep.assessmentResult:
          _patternIndex = _patternAnswers.length - 1;
          _step = _ProfileStep.pattern;
          break;
        case _ProfileStep.dietType:
        case _ProfileStep.review:
          _step = _ProfileStep.assessmentResult;
          break;
        case _ProfileStep.fodmapPhase:
          _step = _ProfileStep.dietType;
          break;
        case _ProfileStep.avoidedIngredients:
          _step = _dietType == 'Low FODMAP'
              ? _ProfileStep.fodmapPhase
              : _ProfileStep.dietType;
          break;
        case _ProfileStep.portionLimits:
          _step = _ProfileStep.avoidedIngredients;
          break;
        case _ProfileStep.allergies:
          _step = _ProfileStep.portionLimits;
          break;
        case _ProfileStep.tolerances:
          _step = _ProfileStep.allergies;
          break;
        case _ProfileStep.budget:
          _step = _ProfileStep.tolerances;
          break;
        case _ProfileStep.spicy:
          _step = _ProfileStep.budget;
          break;
        case _ProfileStep.otherPreferences:
          _step = _ProfileStep.spicy;
          break;
      }
    });
  }

  void _openReviewEdit(_ProfileStep step) {
    setState(() {
      _returnToReview = true;
      _step = step;
    });
  }

  void _changePortion(String ingredient, int delta) {
    setState(() {
      final current = _portionLimits[ingredient] ?? 0;
      _portionLimits[ingredient] = (current + delta).clamp(0, 10).toInt();
    });
  }

  void _toggle(Set<String> values, String value) {
    setState(() {
      if (!values.add(value)) values.remove(value);
    });
  }

  void _addAvoidedIngredient() =>
      _addValue(_avoidController, _avoidedIngredients);

  void _addAllergy() => _addValue(_allergyController, _allergies);

  void _addTolerance() => _addValue(_toleranceController, _tolerances);

  void _addValue(TextEditingController controller, Set<String> values) {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    setState(() {
      values.add(value);
      controller.clear();
    });
  }

  Future<void> _callEmergency() async {
    final launched = await launchUrl(Uri(scheme: 'tel', path: '119'));
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka aplikasi telepon.')),
      );
    }
  }

  Future<void> _showAnswersSummary() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ringkasan jawaban'),
        content: Text(
          'Usia: ${_ageBand ?? 'Belum dijawab'}\n'
          'Diagnosis IBS: ${_diagnosis ?? 'Belum dijawab'}\n'
          'Arahan makan: ${_clinicianGuidance ?? 'Belum dijawab'}\n'
          '${[for (var i = 0; i < _redFlags.length; i++) '${_redFlagQuestions[i]} ${_redFlags[i] ?? 'Belum dijawab'}'].join('\n')}\n'
          'Perdarahan sedang terjadi: ${_bleedingActive ?? 'Belum dijawab'}\n'
          '${[for (var i = 0; i < _patternAnswers.length; i++) 'Q${i + 1}: ${_patternAnswers[i] ?? 'Belum dijawab'}'].join('\n')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _persistProgress();
    _finishing = true;
    await _progressSave;
    if (_progressFailed) {
      _finishing = false;
      return;
    }
    if (mounted) widget.onComplete(_createAnswers());
    _finishing = false;
  }

  ProfileSetupAnswers _createAnswers() => ProfileSetupAnswers(
    displayName: widget.displayName,
    email: widget.email,
    ageBand: _ageBand,
    diagnosis: _diagnosis,
    clinicianGuidance: _clinicianGuidance,
    redFlags: _redFlags,
    pattern: _patternAnswers,
    dietType: _dietType,
    dietPhase: _dietPhase,
    avoidedIngredients: _avoidedIngredients.toList(),
    portionLimits: _portionLimits,
    allergies: _allergies.toList(),
    tolerances: _tolerances.toList(),
    budget: _budget,
    spicy: _spicy,
    preferences: _preferences.toList(),
    aiEnabled: widget.aiEnabled,
    bleedingActive: _bleedingActive,
  );

  String get _dietSummary {
    if (_dietType == null) return 'Belum dipilih';
    if (_dietType == 'Low FODMAP' && _dietPhase != null) {
      return 'Low FODMAP · ${_dietPhase!.toLowerCase()}';
    }
    return _dietType!;
  }

  String get _portionSummary {
    final limits = _portionLimits.entries
        .where((entry) => (entry.value ?? 0) > 0)
        .map((entry) => '${entry.key} ${entry.value} porsi')
        .join(' · ');
    return limits.isEmpty ? 'Tidak ada' : limits;
  }

  String _listSummary(Set<String> values, {String empty = 'Belum dipilih'}) =>
      values.isEmpty ? empty : values.join(' · ');

  String _formatRupiah(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.detail,
  });

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AibsColors.card,
      borderRadius: BorderRadius.circular(AibsRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AibsRadius.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: AibsSize.optionMin),
          padding: const EdgeInsets.all(AibsSpace.s16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AibsRadius.lg),
            border: Border.all(
              color: selected ? AibsColors.primary : AibsColors.line,
              width: selected ? AibsSpace.s2 : 1,
            ),
            boxShadow: AibsShadows.card,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: AibsType.option),
                    if (detail != null) ...[
                      const SizedBox(height: AibsSpace.s4),
                      Text(
                        detail!,
                        style: AibsType.caption.copyWith(
                          color: AibsColors.inkMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.chevron_right,
                color: selected ? AibsColors.primary : AibsColors.inkMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.number,
    required this.title,
    required this.detail,
  });

  final int number;
  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AibsSize.helpStepCircle,
          height: AibsSize.helpStepCircle,
          decoration: const BoxDecoration(
            color: AibsColors.badSoft,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: AibsType.bodyStrong.copyWith(color: AibsColors.badInk),
            ),
          ),
        ),
        const SizedBox(width: AibsSpace.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AibsType.bodyStrong),
              if (detail != null) ...[
                const SizedBox(height: AibsSpace.s4),
                Text(
                  detail!,
                  style: AibsType.caption.copyWith(color: AibsColors.inkMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
