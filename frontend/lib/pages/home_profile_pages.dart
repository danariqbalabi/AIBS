import 'dart:async';

import '../data/app_services.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/demo_data.dart';
import '../core/theme/aibs_tokens.dart';
import 'profile_setup_flow.dart';
import '../shared/widgets/koala.dart';
import '../shared/widgets/status_badge.dart';
import '../theme/aibs_theme.dart';
import '../widgets/aibs_widgets.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    required this.onOpenCamera,
    required this.profile,
    required this.meals,
    required this.symptoms,
    required this.onOpenMenu,
    required this.onOpenProfile,
    required this.onOpenJournal,
    required this.onOpenSummary,
    required this.onAddSymptom,
    required this.onLogNoSymptoms,
    required this.onOpenMenuItem,
    required this.showSymptomPrompt,
    super.key,
    this.plan,
    this.menus,
    this.serverMode,
    this.plans = const [],
  });

  final VoidCallback onOpenCamera;
  final ProfileSetupAnswers? profile;
  final List<AibsMealLog> meals;
  final List<AibsSymptomLog> symptoms;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenJournal;
  final VoidCallback onOpenSummary;
  final VoidCallback onAddSymptom;
  final VoidCallback onLogNoSymptoms;
  final ValueChanged<AibsMenuItem> onOpenMenuItem;
  final bool showSymptomPrompt;
  final AibsMealPlan? plan;
  final List<AibsMenuItem>? menus;
  final String? serverMode;
  final List<AibsMealPlan> plans;

  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName;
    final greetingName = name == null || name.isEmpty ? 'Nadia' : name;
    final hasDiet = serverMode != null
        ? serverMode == 'diet_support'
        : profile?.dietType != null && profile!.dietType != 'Belum ada arahan';
    final visiblePlans = plans.isNotEmpty ? plans : [?plan];
    final mealLabel = _mealLabel(DateTime.now().hour);
    final hasMeals = meals.any(
      (meal) => DateUtils.isSameDay(meal.date, DateTime.now()),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 28),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hai, $greetingName', style: AibsType.greeting),
              const SizedBox(height: AibsSpace.s2),
              Text(
                hasDiet ? 'Mau $mealLabel apa?' : 'Mau catat apa hari ini?',
                style: AibsType.title,
              ),
            ],
          ),
        ),
        const SizedBox(height: AibsSpace.s24),
        if (!hasDiet)
          _DietPrompt(
            onOpenProfile: onOpenProfile,
            onOpenJournal: onOpenJournal,
          )
        else if (!hasMeals && visiblePlans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
            child: Column(
              children: [
                _OpenMenuCard(
                  onTap: onOpenMenu,
                  count:
                      menus?.where((m) => m.status == CheckStatus.ok).length ??
                      12,
                ),
                const SizedBox(height: AibsSpace.s20),
                AibsCard(
                  child: Column(
                    children: [
                      const Koala(KoalaMood.senang, size: 120),
                      const SizedBox(height: AibsSpace.s8),
                      Text('Belum ada catatan', style: AibsType.verdict),
                      const SizedBox(height: AibsSpace.s12),
                      AibsSecondaryButton(
                        label: 'Catat makan pertama',
                        onPressed: onOpenCamera,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          _RecommendationSlider(
            onOpen: onOpenMenuItem,
            onSeeAll: onOpenMenu,
            menus: menus,
          ),
          for (final scheduled in visiblePlans) ...[
            const SizedBox(height: AibsSpace.s20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
              child: _PlanCard(
                plan: scheduled,
                onTap: () => onOpenMenuItem(scheduled.menu),
              ),
            ),
          ],
          if (hasMeals &&
              !symptoms.any(
                (s) => DateUtils.isSameDay(s.date, DateTime.now()),
              ) &&
              showSymptomPrompt) ...[
            const SizedBox(height: AibsSpace.s20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
              child: _SymptomPrompt(
                onAdd: onAddSymptom,
                onNone: onLogNoSymptoms,
              ),
            ),
          ],
          const SizedBox(height: AibsSpace.s20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
            child: _WeekCard(
              meals: meals,
              symptoms: symptoms,
              onSummary: onOpenSummary,
              onJournal: onOpenJournal,
            ),
          ),
        ],
        if (!hasDiet) ...[
          if (hasMeals)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
              child: _TodayLogCard(meals: meals, onTap: onOpenJournal),
            ),
          for (final scheduled in visiblePlans)
            Padding(
              padding: const EdgeInsets.all(AibsSpace.s20),
              child: _PlanCard(
                plan: scheduled,
                onTap: () => onOpenMenuItem(scheduled.menu),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AibsSpace.s20),
            child: _WeekCard(
              meals: meals,
              symptoms: symptoms,
              onSummary: onOpenSummary,
              onJournal: onOpenJournal,
            ),
          ),
        ],
      ],
    );
  }

  static String _mealLabel(int hour) => switch (hour) {
    < 11 => 'sarapan',
    < 15 => 'makan siang',
    < 19 => 'makan malam',
    _ => 'camilan',
  };
}

class _DietPrompt extends StatelessWidget {
  const _DietPrompt({required this.onOpenProfile, required this.onOpenJournal});
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenJournal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AibsSpace.s20),
      child: Container(
        padding: const EdgeInsets.all(AibsSpace.s16),
        decoration: BoxDecoration(
          color: AibsColors.primarySoft,
          borderRadius: BorderRadius.circular(AibsRadius.lg),
        ),
        child: Column(
          children: [
            const KoalaBubble(
              mood: KoalaMood.mikir,
              koalaSize: 96,
              text: 'Catat makanan dan keluhanmu buat dibawa saat konsultasi.',
            ),
            const SizedBox(height: AibsSpace.s12),
            AibsPrimaryButton(
              label: 'Catat sekarang',
              onPressed: onOpenJournal,
            ),
            TextButton(
              onPressed: onOpenProfile,
              child: const Text('Lengkapi profil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenMenuCard extends StatelessWidget {
  const _OpenMenuCard({required this.onTap, required this.count});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AibsColors.card,
      borderRadius: BorderRadius.circular(AibsRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AibsRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AibsSpace.s16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Lihat $count menu yang sesuai',
                  style: AibsType.bodyStrong,
                ),
              ),
              const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationSlider extends StatelessWidget {
  const _RecommendationSlider({
    required this.onOpen,
    required this.onSeeAll,
    this.menus,
  });
  final List<AibsMenuItem>? menus;
  final ValueChanged<AibsMenuItem> onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final items = (menus ?? aibsDemoMenus)
        .where((menu) => menu.status == CheckStatus.ok)
        .take(3)
        .toList();
    return SizedBox(
      height: 252,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AibsSpace.s20, 4, AibsSpace.s20, 12),
        children: [
          for (final item in items) ...[
            _RecommendationCard(item: item, onTap: () => onOpen(item)),
            const SizedBox(width: AibsSpace.s12),
          ],
          Material(
            color: AibsColors.primarySoft,
            borderRadius: BorderRadius.circular(AibsRadius.lg),
            child: InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(AibsRadius.lg),
              child: SizedBox(
                width: AibsSize.seeAllCard,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      backgroundColor: AibsColors.card,
                      child: Icon(
                        Icons.arrow_forward,
                        color: AibsColors.primaryStrong,
                      ),
                    ),
                    const SizedBox(height: AibsSpace.s8),
                    Text('Lihat semua', style: AibsType.label),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, required this.onTap});
  final AibsMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AibsColors.card,
      borderRadius: BorderRadius.circular(AibsRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AibsRadius.lg),
        child: SizedBox(
          width: AibsSize.menuSliderCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: AibsSize.menuSliderImage,
                decoration: BoxDecoration(
                  gradient: AibsGradients.food(AibsColors.foodBlue),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AibsRadius.lg),
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/illustrations/bowl.svg',
                    width: 56,
                    height: 56,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AibsSpace.s10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AibsType.bodyStrong,
                    ),
                    Text(
                      '${item.kind} · ${item.priceLabel}',
                      style: AibsType.small,
                    ),
                    const SizedBox(height: AibsSpace.s4),
                    const StatusBadge(CheckStatus.ok),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onTap});
  final AibsMealPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AibsCard(
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Text(plan.time, style: AibsType.bodyStrong),
            const SizedBox(width: AibsSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${plan.day} · ${plan.meal}', style: AibsType.small),
                  Text(plan.menu.name, style: AibsType.bodyStrong),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _SymptomPrompt extends StatelessWidget {
  const _SymptomPrompt({required this.onAdd, required this.onNone});
  final VoidCallback onAdd;
  final VoidCallback onNone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AibsSpace.s12),
      decoration: BoxDecoration(
        color: AibsColors.primarySoft,
        borderRadius: BorderRadius.circular(AibsRadius.lg),
      ),
      child: Column(
        children: [
          const KoalaBubble(text: 'Ada keluhan setelah makan pagi tadi?'),
          const SizedBox(height: AibsSpace.s10),
          Row(
            children: [
              Expanded(
                child: AibsSecondaryButton(
                  label: 'Nggak ada',
                  onPressed: onNone,
                ),
              ),
              const SizedBox(width: AibsSpace.s10),
              Expanded(
                child: AibsPrimaryButton(label: 'Catat', onPressed: onAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.meals,
    required this.symptoms,
    required this.onSummary,
    required this.onJournal,
  });
  final List<AibsMealLog> meals;
  final List<AibsSymptomLog> symptoms;
  final VoidCallback onSummary;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final daysWithSymptoms = symptoms
        .where(
          (item) =>
              !DateUtils.dateOnly(item.date)
                  .isBefore(today.subtract(const Duration(days: 6))) &&
              !DateUtils.dateOnly(item.date).isAfter(today),
        )
        .map((item) => DateUtils.dateOnly(item.date))
        .toSet();
    return AibsCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('7 hari terakhir', style: AibsType.bodyStrong),
              ),
              Text(
                '${daysWithSymptoms.length} hari ada gejala',
                style: AibsType.caption,
              ),
            ],
          ),
          const SizedBox(height: AibsSpace.s14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var index = 6; index >= 0; index--)
                _DayDot(
                  date: DateTime.now().subtract(Duration(days: index)),
                  hasSymptom: daysWithSymptoms.contains(
                    DateUtils.dateOnly(
                      DateTime.now().subtract(Duration(days: index)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AibsSpace.s16),
          Row(
            children: [
              Expanded(
                child: AibsSecondaryButton(
                  label: 'Baca pola',
                  onPressed: onSummary,
                ),
              ),
              const SizedBox(width: AibsSpace.s10),
              Expanded(
                child: AibsSecondaryButton(
                  label: 'Lihat riwayat',
                  onPressed: onJournal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.date, required this.hasSymptom});
  final DateTime date;
  final bool hasSymptom;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'S', 'S', 'R', 'K', 'J', 'S'];
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hasSymptom ? AibsColors.primary : AibsColors.unknownSoft,
            shape: BoxShape.circle,
          ),
          child: hasSymptom
              ? Text(
                  '${date.day}',
                  style: AibsType.small.copyWith(color: AibsColors.onPrimary),
                )
              : null,
        ),
        const SizedBox(height: AibsSpace.s4),
        Text(labels[date.weekday % 7], style: AibsType.micro),
      ],
    );
  }
}

class _TodayLogCard extends StatelessWidget {
  const _TodayLogCard({required this.meals, required this.onTap});
  final List<AibsMealLog> meals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AibsCard(
      child: Material(
        color: AibsColors.card,
        borderRadius: BorderRadius.circular(AibsRadius.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hari ini', style: AibsType.sectionTitle),
            const SizedBox(height: AibsSpace.s8),
            for (final meal in meals)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: onTap,
                title: Text(meal.name, style: AibsType.bodyStrong),
                leading: Text(meal.time, style: AibsType.small),
                trailing: const Icon(Icons.chevron_right),
              ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.profile,
    this.onProfileSaved,
    this.onOpenShopping,
    this.onLogout,
    this.onDeleteAll,
    this.onLinkEmail,
    this.onResumeScreening,
    this.onExportData,
    this.shoppingCount = 0,
  });

  final ProfileSetupAnswers? profile;
  final FutureOr<void> Function(ProfileSetupAnswers)? onProfileSaved;
  final VoidCallback? onOpenShopping;
  final VoidCallback? onLogout;
  final VoidCallback? onLinkEmail;
  final VoidCallback? onResumeScreening;
  final FutureOr<void> Function()? onDeleteAll;
  final Future<void> Function()? onExportData;
  final int shoppingCount;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileSetupAnswers? _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) _profile = widget.profile;
  }

  @override
  Widget build(BuildContext context) {
    final profileData = _profile;
    final name = profileData?.displayName;
    final displayName = name == null || name.isEmpty ? 'Nadia' : name;
    final email = profileData?.email;
    final diet = profileData?.dietType;
    final dietPhase = profileData?.dietPhase;
    final dietValue = diet == null
        ? 'Belum diisi'
        : diet == 'Low FODMAP' && dietPhase != null
        ? '$diet · ${dietPhase.toLowerCase()}'
        : diet;
    final avoided = profileData?.avoidedIngredients;
    final allergies = profileData == null
        ? 'Udang'
        : profileData.allergies.isEmpty
        ? 'Nggak ada'
        : profileData.allergies.join(' · ');
    final budgetValue = profileData?.budget;
    final budget = budgetValue == null
        ? 'Maks Rp25.000 per makan'
        : 'Maks $budgetValue per makan';
    final spicyValue = profileData?.spicy;
    final spicy = spicyValue == null
        ? 'Sedikit pedas'
        : switch (spicyValue) {
            'Nggak pedas' => 'Nggak pedas',
            'Sedikit' => 'Sedikit pedas',
            'Sedang' => 'Sedang pedas',
            'Pedas banget' => 'Pedas banget',
            _ => spicyValue,
          };
    final preferences = profileData?.preferences;
    final screeningResult = profileData?.pattern.isNotEmpty == true
        ? 'Selesai'
        : 'Belum diisi';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text('Profil', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        AibsCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AibsColors.primarySoft,
                child: Icon(
                  Icons.person_outline,
                  color: AibsColors.primaryStrong,
                  size: 30,
                ),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email == null || email.isEmpty ? 'Nama panggilan' : email,
                    style: TextStyle(color: AibsColors.inkMuted, fontSize: 12),
                  ),
                  SizedBox(height: 3),
                  Text(
                    displayName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.onLinkEmail != null)
          TextButton(
            onPressed: widget.onLinkEmail,
            child: const Text('Hubungkan email'),
          ),
        const SizedBox(height: 20),
        _ProfileSection(
          title: 'Pengecekan awal',
          value: screeningResult,
          detail: 'Lihat jawaban awal',
          onTap: widget.onResumeScreening ?? _openScreening,
        ),
        const SizedBox(height: 12),
        _ProfileSection(
          title: 'Arahan makan',
          value: dietValue,
          detail: avoided == null || avoided.isEmpty
              ? 'Belum ada bahan dihindari'
              : avoided.join(' · '),
          onTap: _openEdit,
        ),
        const SizedBox(height: 12),
        _ProfileSection(
          title: 'Alergi',
          value: allergies,
          detail: 'Bisa kamu ubah kapan saja',
        ),
        const SizedBox(height: 12),
        _ProfileSection(
          title: 'Budget & preferensi',
          value: budget,
          detail: [
            spicy,
            if (preferences != null && preferences.isNotEmpty)
              preferences.join(' · '),
          ].join(' · '),
        ),
        const SizedBox(height: AibsSpace.s12),
        _ProfileSection(
          title: 'Checklist belanja',
          value: '${widget.shoppingCount} bahan belum dibeli',
          detail: 'Buka checklist',
          onTap: widget.onOpenShopping,
        ),
        const SizedBox(height: AibsSpace.s12),
        _ProfileSection(
          title: 'Privasi & AI',
          value: profileData?.aiEnabled == false
              ? 'Tanpa AI'
              : 'Bantuan AI aktif',
          detail: 'Ubah izin dan data',
          onTap: _openPrivacy,
        ),
        const SizedBox(height: AibsSpace.s12),
        TextButton(
          onPressed: widget.onLogout,
          child: Text(
            'Keluar',
            style: AibsType.label.copyWith(color: AibsColors.badInk),
          ),
        ),
      ],
    );
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.of(context).push<ProfileSetupAnswers>(
      MaterialPageRoute(
        builder: (_) => _EditDietPage(profile: _profile ?? _demoProfile),
      ),
    );
    if (updated == null || !mounted) return;
    try {
      await widget.onProfileSaved?.call(updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppServices.message(error))));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _profile = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan tersimpan untuk sesi ini')),
    );
  }

  Future<void> _openPrivacy() async {
    final profile = _profile;
    if (profile == null) return;
    final result = await Navigator.of(context)
        .push<({bool aiEnabled, bool savePhotos})>(
          MaterialPageRoute(
            builder: (_) => _PrivacyPage(
              profile: profile,
              onDeleteAll: widget.onDeleteAll ?? widget.onLogout ?? () {},
              onExportData: widget.onExportData,
            ),
          ),
        );
    if (result == null || !mounted) return;
    final updated = profile.copyWithDietProfile(
      dietType: profile.dietType,
      dietPhase: profile.dietPhase,
      avoidedIngredients: profile.avoidedIngredients,
      portionLimits: profile.portionLimits,
      aiEnabled: result.aiEnabled,
      savePhotos: result.savePhotos,
    );
    if (updated.aiEnabled == profile.aiEnabled &&
        updated.savePhotos == profile.savePhotos) {
      return;
    }
    try {
      await widget.onProfileSaved?.call(updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppServices.message(error))));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _profile = updated);
  }

  void _openScreening() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Jawaban pengecekan awal tersimpan di sesi ini'),
      ),
    );
  }

  static ProfileSetupAnswers get _demoProfile => ProfileSetupAnswers(
    displayName: 'Nadia',
    email: '',
    ageBand: null,
    diagnosis: null,
    clinicianGuidance: null,
    redFlags: const [],
    pattern: const [],
    dietType: 'Low FODMAP',
    dietPhase: 'Eliminasi',
    avoidedIngredients: const ['Bawang putih', 'Bawang bombay', 'Susu sapi'],
    portionLimits: const {'Nasi': 1, 'Buah': 1, 'Roti': null},
    allergies: const ['Udang'],
    tolerances: const [],
    budget: 'Rp25.000',
    spicy: 'Sedikit',
    preferences: const [],
  );
}

class _PrivacyPage extends StatefulWidget {
  const _PrivacyPage({
    required this.profile,
    required this.onDeleteAll,
    this.onExportData,
  });
  final ProfileSetupAnswers profile;
  final FutureOr<void> Function() onDeleteAll;
  final Future<void> Function()? onExportData;

  @override
  State<_PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<_PrivacyPage> {
  late bool _aiEnabled = widget.profile.aiEnabled;
  late bool _savePhoto = widget.profile.savePhotos;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privasi')),
      body: ListView(
        padding: const EdgeInsets.all(AibsSpace.s20),
        children: [
          AibsCard(
            padding: 0,
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Bantuan AI'),
                    subtitle: const Text('Foto dan cerita dirapikan otomatis'),
                    value: _aiEnabled,
                    onChanged: (value) => setState(() => _aiEnabled = value),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Simpan foto makanan'),
                    subtitle: const Text(
                      'Foto sementara kedaluwarsa setelah 24 jam. Penghapusan fisik mengikuti jadwal pembersihan layanan.',
                    ),
                    value: _savePhoto,
                    onChanged: (value) => setState(() => _savePhoto = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AibsSpace.s16),
          AibsSecondaryButton(
            label: 'Unduh data saya',
            onPressed: _busy ? null : _exportProfile,
          ),
          const SizedBox(height: AibsSpace.s10),
          AibsSecondaryButton(
            label: 'Hapus semua data',
            onPressed: _busy ? null : _confirmDelete,
          ),
          const SizedBox(height: AibsSpace.s20),
          AibsPrimaryButton(
            label: 'Simpan',
            onPressed: () => Navigator.pop(context, (
              aiEnabled: _aiEnabled,
              savePhotos: _savePhoto,
            )),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus semua data?'),
        content: const Text(
          'Profil, catatan, draft, rencana, daftar belanja, dan foto dihapus. Akun login tetap ada. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      setState(() => _busy = true);
      try {
        await widget.onDeleteAll();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppServices.message(error))));
        }
        return;
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _exportProfile() async {
    if (widget.onExportData != null) {
      setState(() => _busy = true);
      try {
        await widget.onExportData!();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppServices.message(error))));
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    final data = [
      'Nama: ${widget.profile.displayName}',
      'Arahan makan: ${widget.profile.dietType ?? 'Belum diisi'}',
      'Fase: ${widget.profile.dietPhase ?? 'Belum diisi'}',
      'Bahan dihindari: ${widget.profile.avoidedIngredients.join(', ')}',
      'Alergi: ${widget.profile.allergies.join(', ')}',
      'Batas porsi: ${widget.profile.portionLimits}',
      'Budget: ${widget.profile.budget ?? 'Belum diisi'}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: data));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data disalin. Kamu bisa menyimpannya.')),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.value,
    required this.detail,
    this.onTap,
  });

  final String title;
  final String value;
  final String detail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AibsCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: onTap == null ? EdgeInsets.zero : const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(detail, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AibsColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditDietPage extends StatefulWidget {
  const _EditDietPage({required this.profile});

  final ProfileSetupAnswers profile;

  @override
  State<_EditDietPage> createState() => _EditDietPageState();
}

class _EditDietPageState extends State<_EditDietPage> {
  static const _dietTypes = [
    'Low FODMAP',
    'Rendah lemak',
    'Tinggi serat',
    'Belum ada arahan',
    'Lainnya',
  ];
  static const _dietPhases = [
    'Eliminasi',
    'Reintroduksi',
    'Personalisasi',
    'Belum tahu',
  ];

  late String _dietType;
  late String _dietPhase;
  late final Map<String, bool> _avoided;
  late final Map<String, int?> _portionLimits;
  final _customController = TextEditingController();
  final _portionController = TextEditingController();
  String? _ingredientError;
  String? _portionError;

  @override
  void initState() {
    super.initState();
    _dietType = widget.profile.dietType ?? 'Belum ada arahan';
    _dietPhase = widget.profile.dietPhase ?? 'Belum tahu';
    _avoided = {
      for (final ingredient in widget.profile.avoidedIngredients)
        ingredient: true,
    };
    _portionLimits = Map.of(widget.profile.portionLimits);
  }

  @override
  void dispose() {
    _customController.dispose();
    _portionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arahan diet')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Jenis arahan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: _dietType,
                  onChanged: (value) {
                    if (value != null) setState(() => _dietType = value);
                  },
                  child: Column(
                    children: [
                      for (final item in _dietTypes)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item),
                          value: item,
                        ),
                    ],
                  ),
                ),
                if (_dietType == 'Low FODMAP') ...[
                  const SizedBox(height: 8),
                  Text(
                    'Fase Low FODMAP',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final phase in _dietPhases)
                        AibsChoiceChip(
                          label: phase,
                          selected: _dietPhase == phase,
                          onTap: () => setState(() => _dietPhase = phase),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Bahan yang dihindari',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _customController,
                  decoration: InputDecoration(
                    hintText: 'Tambah bahan',
                    errorText: _ingredientError,
                    suffixIcon: IconButton(
                      tooltip: 'Tambah bahan',
                      onPressed: _addIngredient,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                  onChanged: (_) => setState(() => _ingredientError = null),
                  onSubmitted: (_) => _addIngredient(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in _avoided.entries)
                      InputChip(
                        label: Text(
                          entry.key,
                          style: TextStyle(
                            decoration: entry.value
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        selected: entry.value,
                        onPressed: () => _toggleAvoided(entry.key),
                        deleteButtonTooltipMessage: entry.value
                            ? 'Hapus ${entry.key}'
                            : 'Pulihkan ${entry.key}',
                        deleteIcon: Icon(
                          entry.value ? Icons.close : Icons.undo,
                        ),
                        onDeleted: () => _toggleAvoided(entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Batas porsi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final item in _portionLimits.keys.toList())
                  _portionRow(item),
                const SizedBox(height: 12),
                TextField(
                  controller: _portionController,
                  decoration: InputDecoration(
                    hintText: 'Tambah batas porsi',
                    errorText: _portionError,
                    suffixIcon: IconButton(
                      tooltip: 'Tambah batas porsi',
                      onPressed: _addPortionLimit,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _portionError = null),
                  onSubmitted: (_) => _addPortionLimit(),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: AibsPrimaryButton(
                  label: 'Simpan perubahan',
                  onPressed: _save,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addIngredient() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    if (_avoided[value] == true) {
      setState(() => _ingredientError = 'Bahan ini sudah ada.');
      return;
    }
    setState(() {
      _avoided[value] = true;
      _ingredientError = null;
    });
    _customController.clear();
  }

  Widget _portionRow(String ingredient) {
    final portion = _portionLimits[ingredient] ?? 0;
    return AibsCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              ingredient,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Kurangi porsi $ingredient',
            onPressed: () => _changePortion(ingredient, -1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            portion == 0 ? 'Tidak ada' : '$portion porsi',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            tooltip: 'Tambah porsi $ingredient',
            onPressed: () => _changePortion(ingredient, 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  void _changePortion(String ingredient, int delta) {
    setState(() {
      final current = _portionLimits[ingredient] ?? 0;
      _portionLimits[ingredient] = (current + delta).clamp(0, 10).toInt();
    });
  }

  void _addPortionLimit() {
    final ingredient = _portionController.text.trim();
    if (ingredient.isEmpty) return;
    if (_portionLimits.containsKey(ingredient)) {
      setState(() => _portionError = 'Batas porsi ini sudah ada.');
      return;
    }
    setState(() {
      _portionLimits[ingredient] = 0;
      _portionError = null;
    });
    _portionController.clear();
  }

  void _toggleAvoided(String ingredient) {
    setState(() => _avoided[ingredient] = !(_avoided[ingredient] ?? false));
  }

  List<String> get _sensitiveChanges {
    final initialAvoided = widget.profile.avoidedIngredients.toSet();
    final currentAvoided = _avoided.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
    final changes = [
      for (final ingredient in initialAvoided.difference(currentAvoided))
        'Hapus $ingredient dari daftar hindari',
    ];
    for (final entry in widget.profile.portionLimits.entries) {
      final previous = entry.value ?? 0;
      final current = _portionLimits[entry.key] ?? 0;
      if (previous > 0 && current < previous) {
        changes.add('Longgarkan batas porsi ${entry.key.toLowerCase()}');
      }
    }
    return changes;
  }

  Future<void> _save() async {
    final changes = _sensitiveChanges;
    if (changes.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _ConfirmProfileDialog(changes: changes),
      );
      if (confirmed != true || !mounted) return;
    }

    final profile = widget.profile.copyWithDietProfile(
      dietType: _dietType,
      dietPhase: _dietType == 'Low FODMAP' ? _dietPhase : null,
      avoidedIngredients: _avoided.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
      portionLimits: _portionLimits,
    );
    if (mounted) Navigator.of(context).pop(profile);
  }
}

class _ConfirmProfileDialog extends StatelessWidget {
  const _ConfirmProfileDialog({required this.changes});

  final List<String> changes;

  @override
  Widget build(BuildContext context) {
    final title = changes.length == 1
        ? '${changes.single}?'
        : 'Ada perubahan yang melonggarkan batas diet?';
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Koala(KoalaMood.mikir, size: 110),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (changes.length > 1) ...[
            for (final change in changes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(change, textAlign: TextAlign.center),
              ),
            const SizedBox(height: 8),
          ],
          const Text(
            'Pastikan sesuai arahan dokter atau ahli gizimu.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Ya, ubah'),
        ),
      ],
    );
  }
}
