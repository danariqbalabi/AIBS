import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'core/demo_data.dart';
import 'pages/home_profile_pages.dart';
import 'pages/menu_flow.dart';
import 'pages/onboarding_flow.dart';
import 'pages/profile_setup_flow.dart';
import 'pages/record_pages.dart';
import 'pages/summary_pages.dart';
import 'theme/aibs_theme.dart';
import 'widgets/aibs_tab_bar.dart';

void main() {
  runApp(const AibsApp());
}

class AibsApp extends StatefulWidget {
  const AibsApp({super.key});

  @override
  State<AibsApp> createState() => _AibsAppState();
}

class _AibsAppState extends State<AibsApp> {
  bool _onboardingComplete = false;
  ProfileSetupAnswers? _profile;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIBS',
      debugShowCheckedModeBanner: false,
      theme: AibsTheme.light,
      home: _onboardingComplete
          ? AibsHomeShell(
              profile: _profile,
              onProfileSaved: (profile) => setState(() => _profile = profile),
              onLogout: () => setState(() {
                _profile = null;
                _onboardingComplete = false;
              }),
            )
          : OnboardingFlow(
              onComplete: (profile) => setState(() {
                _profile = profile;
                _onboardingComplete = true;
              }),
            ),
    );
  }
}

class AibsHomeShell extends StatefulWidget {
  const AibsHomeShell({
    super.key,
    this.profile,
    this.onProfileSaved,
    this.onLogout,
  });

  final ProfileSetupAnswers? profile;
  final ValueChanged<ProfileSetupAnswers>? onProfileSaved;
  final VoidCallback? onLogout;

  @override
  State<AibsHomeShell> createState() => _AibsHomeShellState();
}

class _AibsHomeShellState extends State<AibsHomeShell> {
  int _selectedIndex = 0;
  final List<AibsMealLog> _meals = [];
  final List<AibsSymptomLog> _symptoms = [];
  final List<AibsStoryLog> _stories = [];
  final List<String> _shoppingItems = [
    'Ayam paha · 200 g · 2 resep',
    'Kecap manis · 2 sdm',
    'Jahe · 2 ruas',
    'Tahu putih · 2 potong',
  ];
  AibsMealPlan? _plan;
  bool _didNoSymptomCheckin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            TodayPage(
              profile: widget.profile,
              meals: _meals,
              symptoms: _symptoms,
              plan: _plan,
              showSymptomPrompt: !_didNoSymptomCheckin,
              onOpenCamera: () => _showCameraIntent(),
              onOpenMenu: () => setState(() => _selectedIndex = 1),
              onOpenProfile: () => setState(() => _selectedIndex = 3),
              onOpenJournal: () => setState(() => _selectedIndex = 2),
              onOpenSummary: _openSummary,
              onAddSymptom: _openSymptomEntry,
              onLogNoSymptoms: () => setState(() {
                _didNoSymptomCheckin = true;
              }),
              onOpenMenuItem: _openMenuItem,
            ),
            MenuHomePage(
              profile: widget.profile,
              shoppingItems: _shoppingItems,
              onShoppingChanged: _updateShoppingItems,
              onStartMealRecord: _openMealRecord,
              onPlanSaved: _savePlan,
            ),
            JournalPage(
              meals: _meals,
              symptoms: _symptoms,
              stories: _stories,
              aiEnabled: widget.profile?.aiEnabled ?? true,
              onAddMeal: () => _openCamera(
                initialManualEntry: true,
                intent: MealIntent.eaten,
              ),
              onAddSymptom: _addSymptom,
              onAddStory: (story) => setState(() => _stories.add(story)),
              onDeleteMeal: _deleteMeal,
              onOpenSummary: _openSummary,
            ),
            ProfilePage(
              profile: widget.profile,
              onProfileSaved: widget.onProfileSaved,
              shoppingCount: _shoppingItems.length,
              onOpenShopping: _openShoppingList,
              onLogout: widget.onLogout,
            ),
          ],
        ),
      ),
      bottomNavigationBar: AibsTabBar(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) => setState(() => _selectedIndex = index),
        onCameraPressed: _showCameraIntent,
      ),
    );
  }

  void _showCameraIntent() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AibsSpace.s20,
            AibsSpace.s8,
            AibsSpace.s20,
            AibsSpace.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Foto buat apa?', style: AibsType.sheetTitle),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AibsSpace.s12),
              _CameraIntentCard(
                title: 'Cek sebelum makan',
                subtitle: 'Sesuai arahanku nggak?',
                icon: 'camera.svg',
                highlighted: true,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openCamera(intent: MealIntent.check);
                },
              ),
              const SizedBox(height: AibsSpace.s10),
              _CameraIntentCard(
                title: 'Sudah dimakan',
                subtitle: 'Langsung catat',
                icon: 'check.svg',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openCamera(intent: MealIntent.eaten);
                },
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openCamera(initialManualEntry: true);
                  },
                  child: const Text('Isi manual'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCamera({
    MealIntent intent = MealIntent.check,
    bool initialManualEntry = false,
    String? foodName,
    List<String> ingredients = const [],
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CameraFlowPage(
          intent: intent,
          aiEnabled: widget.profile?.aiEnabled ?? true,
          initialManualEntry: initialManualEntry,
          initialFoodName: foodName,
          initialIngredients: ingredients,
          onSaved: _addMeal,
          onAddSymptom: _openSymptomEntry,
          onFinish: () => setState(() => _selectedIndex = 0),
        ),
      ),
    );
  }

  void _openMenuItem(AibsMenuItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MenuDetailPage(
          item: item,
          onAddShopping: _addShoppingIngredients,
          onStartMealRecord: _openMealRecord,
          onPlanSaved: _savePlan,
        ),
      ),
    );
  }

  void _openMealRecord(AibsMenuItem item) {
    _openCamera(
      intent: MealIntent.eaten,
      initialManualEntry: true,
      foodName: item.name,
      ingredients: item.ingredients,
    );
  }

  void _addMeal(AibsMealLog meal) {
    setState(() {
      _meals.add(meal);
      _didNoSymptomCheckin = false;
    });
  }

  void _addSymptom(AibsSymptomLog symptom) {
    setState(() => _symptoms.add(symptom));
  }

  void _deleteMeal(AibsMealLog meal) {
    setState(() => _meals.remove(meal));
  }

  void _savePlan(AibsMealPlan plan) {
    setState(() => _plan = plan);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Rencana tersimpan')));
  }

  void _addShoppingIngredients(AibsMenuItem item) {
    _updateShoppingItems({..._shoppingItems, ...item.ingredients}.toList());
  }

  void _updateShoppingItems(List<String> items) {
    setState(() {
      _shoppingItems
        ..clear()
        ..addAll(items);
    });
  }

  void _openShoppingList() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShoppingListPage(
          items: _shoppingItems,
          onChanged: _updateShoppingItems,
        ),
      ),
    );
  }

  void _openSymptomEntry() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SymptomEntryPage(
          meals: _meals,
          onSave: (symptom) {
            _addSymptom(symptom);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _openSummary() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SummaryPage(
          meals: _meals,
          symptoms: _symptoms,
          profile: widget.profile,
          onOpenJournal: () => setState(() => _selectedIndex = 2),
        ),
      ),
    );
  }
}

class _CameraIntentCard extends StatelessWidget {
  const _CameraIntentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final String title;
  final String subtitle;
  final String icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted
        ? AibsColors.onPrimary
        : AibsColors.primaryStrong;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AibsRadius.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: highlighted ? null : AibsColors.card,
            gradient: highlighted ? AibsGradients.brand : null,
            borderRadius: BorderRadius.circular(AibsRadius.xl),
            border: highlighted
                ? null
                : Border.all(color: AibsColors.line, width: 2),
            boxShadow: highlighted ? AibsShadows.glow : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AibsSpace.s16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? AibsColors.onPrimary.withValues(alpha: 0.2)
                        : AibsColors.primarySoft,
                    borderRadius: BorderRadius.circular(AibsRadius.md),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/$icon',
                    width: 26,
                    height: 26,
                    colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: AibsSpace.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AibsType.bodyStrong.copyWith(
                          color: highlighted ? AibsColors.onPrimary : null,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AibsType.caption.copyWith(
                          color: highlighted
                              ? AibsColors.primaryTint
                              : AibsColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
