import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'core/demo_data.dart';
import 'data/app_services.dart';
import 'data/records_repository.dart';
import 'data/app_config.dart';
import 'pages/home_profile_pages.dart';
import 'pages/menu_flow.dart';
import 'pages/onboarding_flow.dart';
import 'pages/profile_setup_flow.dart';
import 'pages/record_pages.dart';
import 'pages/summary_pages.dart';
import 'theme/aibs_theme.dart';
import 'widgets/aibs_tab_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final services = await AppServices.create(const AppConfig());
  runApp(AibsApp(services: services));
}

class AibsApp extends StatefulWidget {
  const AibsApp({super.key, this.services});

  final AppServices? services;

  @override
  State<AibsApp> createState() => _AibsAppState();
}

class _AibsAppState extends State<AibsApp> {
  bool _onboardingComplete = false;
  ProfileSetupAnswers? _profile;
  ProfileSetupAnswers? _savedProfile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  void _error(Object error) {
    if (!mounted) return;
    contextForMessages.currentState?.showSnackBar(
      SnackBar(content: Text(AppServices.message(error))),
    );
  }

  final contextForMessages = GlobalKey<ScaffoldMessengerState>();

  Future<bool> _restore() async {
    final services = widget.services;
    if (services?.auth?.auth.currentSession == null) return false;
    try {
      final profile = await services!.profiles.restore(
        services.auth!.auth.currentUser?.email ?? '',
      );
      if (!mounted || profile == null) return false;
      setState(() {
        _profile = profile;
        _onboardingComplete = true;
      });
      return true;
    } catch (error) {
      _error(error);
      return false;
    }
  }

  Future<ProfileSetupAnswers> _demo(String template) async {
    final services = widget.services!;
    final client = services.client;
    final previous = client.auth.currentUser;
    if (previous != null) await services.signOut();
    await client.auth.signInAnonymously();
    await services.api.request(
      'POST',
      '/api/v1/demo/sessions',
      body: {'template': template},
    );
    final profile = await services.profiles.restore('');
    if (profile == null) throw StateError('Demo profile missing');
    _savedProfile = profile;
    return profile;
  }

  Future<void> _complete(ProfileSetupAnswers profile) async {
    if (_saving) return;
    _saving = true;
    try {
      final saved = widget.services == null || identical(profile, _savedProfile)
          ? profile
          : await widget.services!.profiles.save(profile);
      if (mounted) {
        setState(() {
          _profile = saved;
          _onboardingComplete = true;
        });
      }
    } catch (error) {
      _error(error);
    } finally {
      _saving = false;
    }
  }

  Future<void> _saveProfile(ProfileSetupAnswers profile) async {
    final saved = widget.services == null
        ? profile
        : await widget.services!.profiles.save(profile);
    if (mounted) setState(() => _profile = saved);
  }

  Future<void> _logout() async {
    try {
      await widget.services?.signOut();
      if (mounted) {
        setState(() {
          _profile = null;
          _onboardingComplete = false;
          _savedProfile = null;
        });
      }
    } catch (error) {
      _error(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIBS',
      scaffoldMessengerKey: contextForMessages,
      debugShowCheckedModeBanner: false,
      theme: AibsTheme.light,
      home: _onboardingComplete
          ? AibsHomeShell(
              services: widget.services,
              profile: _profile,
              onProfileSaved: _saveProfile,
              onLogout: _logout,
            )
          : OnboardingFlow(
              onComplete: _complete,
              onAssess: widget.services?.profiles.assess,
              onDemo: widget.services == null ? null : _demo,
              onSendCode: widget.services?.sendCode,
              onVerifyCode: widget.services == null
                  ? null
                  : (email, code) async {
                      await widget.services!.verifyCode(email, code);
                      return _restore();
                    },
              onConsent: widget.services?.profiles.ensureConsent,
            ),
    );
  }
}

class AibsHomeShell extends StatefulWidget {
  const AibsHomeShell({
    super.key,
    this.profile,
    this.services,
    this.onProfileSaved,
    this.onLogout,
  });

  final ProfileSetupAnswers? profile;
  final AppServices? services;
  final FutureOr<void> Function(ProfileSetupAnswers)? onProfileSaved;
  final VoidCallback? onLogout;

  @override
  State<AibsHomeShell> createState() => _AibsHomeShellState();
}

class _AibsHomeShellState extends State<AibsHomeShell> {
  int _selectedIndex = 0;
  RecordsRepository? _records;
  List<AibsMenuItem>? _menus;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.services != null) {
      _records = RecordsRepository(
        widget.services!.api,
        widget.services!.profiles,
      );
      _menus = [];
      _shoppingItems.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
    }
  }

  @override
  void didUpdateWidget(covariant AibsHomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) _reload();
  }

  Future<void> _reload() async {
    if (_records == null || _loading) return;
    _loading = true;
    try {
      await _records!.load();
      if (!mounted) return;
      setState(() {
        _menus = _records!.menus;
        _meals
          ..clear()
          ..addAll(_records!.meals);
        _symptoms
          ..clear()
          ..addAll(_records!.symptoms);
        _stories
          ..clear()
          ..addAll(_records!.stories);
        _shoppingItems
          ..clear()
          ..addAll(_records!.shoppingLabels);
        _plan = _records!.plan;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppServices.message(error))));
      }
    } finally {
      _loading = false;
    }
  }

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
              menus: _menus,
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
              menus: _menus,
              onAddMenuShopping: _records == null
                  ? null
                  : _addShoppingIngredients,
              checkedShopping: _records?.checkedShopping ?? {},
              onShoppingChecked: _records?.checkShopping,
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
              onAddStory: _addStory,
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
        onTabSelected: (index) {
          setState(() => _selectedIndex = index);
          _reload();
        },
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

  Future<void> _addMeal(AibsMealLog meal) async {
    if (_records != null) {
      await _records!.saveMeal(meal);
      await _reload();
      return;
    }
    setState(() {
      _meals.add(meal);
      _didNoSymptomCheckin = false;
    });
  }

  Future<void> _addSymptom(AibsSymptomLog symptom) async {
    if (_records != null) {
      await _records!.saveSymptom(symptom);
      await _reload();
      return;
    }
    setState(() => _symptoms.add(symptom));
  }

  Future<void> _deleteMeal(AibsMealLog meal) async {
    if (_records != null) {
      await _records!.deleteMeal(meal);
      await _reload();
      return;
    }
    setState(() => _meals.remove(meal));
  }

  Future<void> _savePlan(AibsMealPlan plan) async {
    if (_records != null) {
      await _records!.savePlan(plan);
      await _reload();
      return;
    }
    setState(() => _plan = plan);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Rencana tersimpan')));
  }

  Future<void> _addShoppingIngredients(AibsMenuItem item) async {
    if (_records != null) {
      await _records!.addMenuShopping(item);
      await _reload();
      return;
    }
    await _updateShoppingItems(
      {..._shoppingItems, ...item.ingredients}.toList(),
    );
  }

  Future<void> _addStory(AibsStoryLog story) async {
    if (_records != null) {
      await _records!.saveStory(story);
      await _reload();
      return;
    }
    setState(() => _stories.add(story));
  }

  Future<void> _updateShoppingItems(List<String> items) async {
    if (_records != null) {
      await _records!.replaceShopping(items);
      await _reload();
      return;
    }
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
          initialChecked: _records?.checkedShopping ?? {},
          onChecked: _records?.checkShopping,
          onChanged: _updateShoppingItems,
        ),
      ),
    );
  }

  void _openSymptomEntry() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SymptomEntryPage(meals: _meals, onSave: _addSymptom),
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
          loadSummary: _records?.summary,
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
