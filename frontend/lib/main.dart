import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'pages/home_profile_pages.dart';
import 'pages/menu_flow.dart';
import 'pages/onboarding_flow.dart';
import 'pages/record_pages.dart';
import 'pages/today_page.dart';
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
  OnboardingProfile? _profile;

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return MaterialApp(
      title: 'AIBS',
      debugShowCheckedModeBanner: false,
      theme: AibsTheme.light,
      home: profile != null
          ? AibsHomeShell(profile: profile)
          : OnboardingFlow(
              onComplete: (profile) => setState(() => _profile = profile),
            ),
    );
  }
}

class AibsHomeShell extends StatefulWidget {
  const AibsHomeShell({required this.profile, super.key});

  final OnboardingProfile profile;

  @override
  State<AibsHomeShell> createState() => _AibsHomeShellState();
}

class _AibsHomeShellState extends State<AibsHomeShell> {
  int _selectedIndex = 0;
  final _todayRecords = <TodayLogEntry>[];
  bool _showSymptomPrompt = false;

  @override
  Widget build(BuildContext context) {
    final todayMode = !widget.profile.hasDietProfile
        ? TodayMode.loggingOnly
        : _todayRecords.isEmpty
        ? TodayMode.empty
        : TodayMode.profileComplete;
    return Scaffold(
      body: SafeArea(
        child: switch (_selectedIndex) {
          0 => TodayPage(
            name: widget.profile.name,
            mode: todayMode,
            records: _todayRecords,
            showSymptomPrompt: _showSymptomPrompt,
            onOpenCamera: _showCameraIntent,
            onOpenMenu: () => _selectTab(1),
            onOpenJournal: () => _selectTab(2),
            onOpenProfile: () => _selectTab(3),
            onDismissSymptomPrompt: () =>
                setState(() => _showSymptomPrompt = false),
          ),
          1 => const MenuHomePage(),
          2 => JournalPage(onRecordSaved: _recordJournalSaved),
          3 => const ProfilePage(),
          _ => const SizedBox.shrink(),
        },
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
                    child: Text(
                      'Foto buat apa?',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
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
                onTap: () => _openCameraFlow(sheetContext),
              ),
              const SizedBox(height: AibsSpace.s10),
              _CameraIntentCard(
                title: 'Sudah dimakan',
                subtitle: 'Langsung catat',
                icon: 'check.svg',
                onTap: () => _openCameraFlow(sheetContext),
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () =>
                      _openCameraFlow(sheetContext, manualEntry: true),
                  child: const Text('Isi manual'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCameraFlow(BuildContext sheetContext, {bool manualEntry = false}) {
    Navigator.pop(sheetContext);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: CameraFlowPage(
              initialManualEntry: manualEntry,
              onRecordSaved: _recordMealSaved,
            ),
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  void _recordMealSaved(String title) => _addTodayRecord(title, isMeal: true);

  void _recordJournalSaved(String title) =>
      _addTodayRecord(title, isMeal: false);

  void _addTodayRecord(String title, {required bool isMeal}) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}.'
        '${now.minute.toString().padLeft(2, '0')}';
    setState(() {
      _todayRecords.insert(0, TodayLogEntry(time: time, title: title));
      _showSymptomPrompt = isMeal;
    });
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
        borderRadius: BorderRadius.circular(AibsRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: highlighted ? null : AibsColors.card,
            gradient: highlighted ? AibsGradients.brand : null,
            borderRadius: BorderRadius.circular(AibsRadius.lg),
            border: highlighted
                ? null
                : Border.all(color: AibsColors.line, width: 2),
            boxShadow: highlighted ? AibsShadows.glow : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AibsSpace.s16),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/$icon',
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
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
