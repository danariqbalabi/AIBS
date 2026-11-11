import 'package:flutter/material.dart';

import 'pages/home_profile_pages.dart';
import 'pages/onboarding_flow.dart';
import 'theme/aibs_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIBS',
      debugShowCheckedModeBanner: false,
      theme: AibsTheme.light,
      home: _onboardingComplete
          ? const AibsHomeShell()
          : OnboardingFlow(
              onComplete: () => setState(() => _onboardingComplete = true),
            ),
    );
  }
}

class AibsHomeShell extends StatefulWidget {
  const AibsHomeShell({super.key});

  @override
  State<AibsHomeShell> createState() => _AibsHomeShellState();
}

class _AibsHomeShellState extends State<AibsHomeShell> {
  int _selectedIndex = 0;

  static const _titles = [
    'Hari Ini',
    'Menu',
    'Foto makanan',
    'Jurnal',
    'Profil',
  ];
  static const _icons = [
    Icons.home_outlined,
    Icons.restaurant_menu_outlined,
    Icons.camera_alt_outlined,
    Icons.menu_book_outlined,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: switch (_selectedIndex) {
          0 => TodayPage(
            onOpenCamera: () => setState(() => _selectedIndex = 2),
          ),
          4 => const ProfilePage(),
          _ => Center(
            child: Text(
              _titles[_selectedIndex],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          for (var index = 0; index < _titles.length; index++)
            NavigationDestination(
              icon: Icon(_icons[index]),
              label: _titles[index],
            ),
        ],
      ),
    );
  }
}
