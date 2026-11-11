import 'package:flutter/material.dart';

import 'pages/onboarding_flow.dart';
import 'theme/aibs_theme.dart';
import 'widgets/aibs_widgets.dart';

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
    final title = _titles[_selectedIndex];
    return Scaffold(
      body: SafeArea(
        child: _selectedIndex == 0
            ? _buildToday(context)
            : Center(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
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

  Widget _buildToday(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Hari Ini', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        const AibsCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hai, Nadia!'),
                    SizedBox(height: 8),
                    Text('Mau catat apa hari ini?'),
                  ],
                ),
              ),
              AibsMascot(expression: 'senang', size: 92),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AibsPrimaryButton(
          label: 'Catat makanan',
          icon: Icons.camera_alt_outlined,
          onPressed: () => setState(() => _selectedIndex = 2),
        ),
      ],
    );
  }
}
