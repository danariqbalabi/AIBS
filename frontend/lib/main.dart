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
import 'widgets/load_gate.dart';
import 'pages/link_email_sheet.dart';
import 'pages/draft_review_page.dart';
import 'data/photo_picker.dart';
import 'data/export_file.dart';

import 'dart:typed_data';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PhotoPicker.recover();
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
  bool _restoring = false;
  String? _restoreError;

  @override
  void initState() {
    super.initState();
    _restoring = widget.services?.identity.hasSession ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore(gate: true));
  }

  void _error(Object error) {
    if (!mounted) return;
    contextForMessages.currentState?.showSnackBar(
      SnackBar(content: Text(AppServices.message(error))),
    );
  }

  final contextForMessages = GlobalKey<ScaffoldMessengerState>();
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<bool> _restore({bool gate = false}) async {
    final services = widget.services;
    if (services == null || !services.identity.hasSession) {
      if (gate && mounted) {
        setState(() {
          _restoring = false;
          _restoreError = null;
        });
      }
      return false;
    }
    if (gate && mounted) {
      setState(() {
        _restoring = true;
        _restoreError = null;
      });
    }
    try {
      final profile = await services.profiles.restore(services.identity.email);
      if (!mounted || profile == null) return false;
      setState(() {
        _profile = profile;
        _onboardingComplete = true;
      });
      return true;
    } catch (error) {
      if (!gate) rethrow;
      if (mounted) setState(() => _restoreError = AppServices.message(error));
      return false;
    } finally {
      if (gate && mounted) setState(() => _restoring = false);
    }
  }

  Future<ProfileSetupAnswers> _demo(String template) async {
    final profile = await widget.services!.openDemo(template);
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

  Future<void> _linkEmail() async {
    final services = widget.services!;
    await showModalBottomSheet<bool>(
      context: navigatorKey.currentState!.overlay!.context,
      isScrollControlled: true,
      builder: (_) => LinkEmailSheet(
        sendCode: services.beginEmailLink,
        verifyCode: (email, code) async {
          final profile = await services.confirmEmailLink(email, code);
          if (mounted) setState(() => _profile = profile);
        },
      ),
    );
  }

  Future<void> _logout({bool dataDeleted = false}) async {
    if (!dataDeleted && widget.services?.identity.isAnonymous == true) {
      final navigatorContext = navigatorKey.currentState!.overlay!.context;
      final confirmed = await showDialog<bool>(
        context: navigatorContext,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Keluar dari demo?'),
          content: const Text(
            'Catatan tersimpan untuk sesi demo ini. Setelah keluar, memilih Nadia atau Raka membuat sesi baru. Gunakan login email untuk akun yang bisa dimasuki kembali.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Keluar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      await widget.services?.signOut();
      if (mounted) {
        setState(() {
          _profile = null;
          _onboardingComplete = false;
          _savedProfile = null;
          _restoreError = null;
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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AibsTheme.light,
      home: (_restoring || _restoreError != null)
          ? LoadGate(
              busy: _restoring,
              message: _restoreError ?? 'Memulihkan sesi...',
              onRetry: () => _restore(gate: true),
              onLogout: _logout,
            )
          : _onboardingComplete
          ? AibsHomeShell(
              services: widget.services,
              profile: _profile,
              onProfileSaved: _saveProfile,
              onDataDeleted: () => _logout(dataDeleted: true),
              onLinkEmail: widget.services?.identity.isAnonymous == true
                  ? _linkEmail
                  : null,
              onLogout: _logout,
            )
          : OnboardingFlow(
              initialProgress:
                  widget.services?.profiles.onboardingProgress ?? const {},
              sessionEmail: widget.services?.identity.email ?? '',
              onProgress: widget.services?.profiles.saveProgress,
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
    this.onLinkEmail,
    this.onProfileSaved,
    this.onLogout,
    this.onDataDeleted,
  });

  final ProfileSetupAnswers? profile;
  final AppServices? services;
  final VoidCallback? onLinkEmail;
  final FutureOr<void> Function(ProfileSetupAnswers)? onProfileSaved;
  final VoidCallback? onLogout;
  final Future<void> Function()? onDataDeleted;

  @override
  State<AibsHomeShell> createState() => _AibsHomeShellState();
}

class _AibsHomeShellState extends State<AibsHomeShell> {
  int _selectedIndex = 0;
  DateTime? _evidenceDate;
  String? _evidenceSymptom;
  RecordsRepository? _records;
  List<AibsMenuItem>? _menus;
  bool _loading = false;
  bool _hasLoaded = false;
  bool _reloadAgain = false;
  String? _loadError;

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
    if (_records == null) return;
    if (_loading) {
      _reloadAgain = true;
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _records!.load();
      if (!mounted) return;
      setState(() {
        _hasLoaded = true;
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
        _didNoSymptomCheckin = _records!.noSymptomsForLatestMeal;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = AppServices.message(error));
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppServices.message(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (_reloadAgain && mounted) {
      _reloadAgain = false;
      await _reload();
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
    if (_records != null && !_hasLoaded) {
      return LoadGate(
        busy: _loading || _loadError == null,
        message: _loadError ?? 'Memuat catatan tersimpan...',
        onRetry: _reload,
        onLogout: widget.onLogout,
      );
    }
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            TodayPage(
              serverMode: _records?.dashboard['mode'] as String?,
              plans: _records?.todayPlans ?? const [],
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
              onLogNoSymptoms: _noSymptoms,
              onOpenMenuItem: _openMenuItem,
            ),
            MenuHomePage(
              onCheckMenu: _records?.checkCard,
              ingredientId: widget.services?.profiles.ingredientId,
              onShoppingQuantity: _records?.changeShoppingQuantity,
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
              onManualStory: _records == null ? null : _reviewManualStory,
              onSaveSymptomDraft: _records?.saveSymptomDraft,
              evidenceDate: _evidenceDate,
              evidenceSymptom: _evidenceSymptom,
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
              onAnalyzeStory: _records == null ? null : _reviewStory,
              onResumeDraft: _records == null ? null : _resumeDraft,
              onDeleteMeal: _deleteMeal,
              onDeleteSymptom: _records == null ? null : _deleteSymptom,
              onEditEvent: _records == null ? null : _editEvent,
              ingredientId: widget.services?.profiles.ingredientId,
              onOpenSummary: _openSummary,
            ),
            ProfilePage(
              onResumeScreening: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (routeContext) => ProfileSetupFlow(
                    displayName: widget.profile?.displayName ?? 'Kamu',
                    email: widget.profile?.email ?? '',
                    aiEnabled: widget.profile?.aiEnabled ?? false,
                    initialAnswers: widget.profile,
                    onAssess: widget.services?.profiles.assess,
                    onBackToAccount: () => Navigator.pop(routeContext),
                    onComplete: (answers) async {
                      try {
                        await widget.onProfileSaved?.call(
                          answers.copyWithDietProfile(
                            dietType: answers.dietType,
                            dietPhase: answers.dietPhase,
                            avoidedIngredients: answers.avoidedIngredients,
                            portionLimits: answers.portionLimits,
                            savePhotos: widget.profile?.savePhotos ?? false,
                          ),
                        );
                        if (routeContext.mounted) Navigator.pop(routeContext);
                      } catch (error) {
                        if (routeContext.mounted) {
                          ScaffoldMessenger.of(routeContext).showSnackBar(
                            SnackBar(content: Text(AppServices.message(error))),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
              profile: widget.profile,
              onProfileSaved: widget.onProfileSaved,
              shoppingCount: _shoppingItems.length,
              onOpenShopping: _openShoppingList,
              onLogout: widget.onLogout,
              onLinkEmail: widget.onLinkEmail,
              onExportData: _records == null
                  ? null
                  : () async {
                      final data = await widget.services!.api.download(
                        '/api/v1/me/data/export',
                      );
                      await exportFile(
                        data,
                        'aibs-data.zip',
                        'application/zip',
                      );
                    },
              onDeleteAll: _records == null
                  ? widget.onLogout
                  : () async {
                      await widget.services!.api.request(
                        'DELETE',
                        '/api/v1/me/data?confirm=true',
                      );
                      await widget.onDataDeleted?.call();
                    },
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
          onFindAlternatives: () => setState(() => _selectedIndex = 1),
          onSaveDraft: _records?.saveManualDraft,
          ingredientId: widget.services?.profiles.ingredientId,
          intent: intent,
          aiEnabled: widget.profile?.aiEnabled ?? true,
          initialManualEntry: initialManualEntry,
          initialFoodName: foodName,
          initialIngredients: ingredients,
          onSaved: _addMeal,
          onCheckFood: _records?.checkFood,
          onReviewPhoto: _records == null ? null : _reviewPhoto,
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
          onCheckMenu: _records?.checkCard,
          ingredientId: widget.services?.profiles.ingredientId,
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

  Future<void> _noSymptoms() async {
    try {
      if (_records != null) await _records!.saveNoSymptoms();
      if (mounted) setState(() => _didNoSymptomCheckin = true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppServices.message(error))));
      }
    }
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

  Future<void> _editEvent(Map<String, dynamic> event) async {
    await _records!.updateEvent(event);
    await _reload();
  }

  Future<void> _deleteSymptom(AibsSymptomLog symptom) async {
    await _records!.deleteSymptom(symptom);
    await _reload();
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
    } else {
      setState(() => _plan = plan);
    }
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _selectedIndex = 0);
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

  Future<bool> _reviewStory(String text, String requestId) async {
    final review = await _records!.analyzeStory(text, requestId);
    if (!mounted) return false;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DraftReviewPage(
          review: review,
          meals: _meals,
          ingredientId: widget.services!.profiles.ingredientId,
          onCheckFood: _records!.checkCard,
        ),
      ),
    );
    await _reload();
    return saved == true;
  }

  Future<void> _resumeDraft(String id) async {
    final review = await _records!.openDraft(id);
    if (!mounted) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DraftReviewPage(
          review: review,
          meals: _meals,
          ingredientId: widget.services!.profiles.ingredientId,
          onCheckFood: _records!.checkCard,
        ),
      ),
    );
    await _reload();
  }

  Future<bool> _reviewManualStory(String text) async {
    final review = await _records!.manualStory(text);
    if (!mounted) return false;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DraftReviewPage(
          review: review,
          meals: _meals,
          ingredientId: widget.services!.profiles.ingredientId,
          onCheckFood: _records!.checkCard,
        ),
      ),
    );
    await _reload();
    return saved == true;
  }

  Future<bool> _reviewPhoto(
    Uint8List bytes,
    String requestId,
    bool consumed,
  ) async {
    final review = await _records!.analyzePhoto(bytes, requestId, consumed);
    if (!mounted) return false;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DraftReviewPage(
          review: review,
          meals: _meals,
          ingredientId: widget.services!.profiles.ingredientId,
          onCheckFood: _records!.checkCard,
        ),
      ),
    );
    await _reload();
    return saved == true;
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
          onQuantity: _records?.changeShoppingQuantity,
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
        builder: (_) => SymptomEntryPage(
          meals: _meals,
          onSave: _addSymptom,
          onSaveDraft: _records?.saveSymptomDraft,
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
          loadSummary: _records?.summary,
          onOpenJournal: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            setState(() => _selectedIndex = 2);
          },
          negativeObservations: _records?.negativeObservations ?? const [],
          onOpenEvidence: (date, symptom) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            setState(() {
              _selectedIndex = 2;
              _evidenceDate = date;
              _evidenceSymptom = symptom;
            });
          },
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
