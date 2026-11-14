import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences extends ChangeNotifier {
  ThemePreferences({
    Future<String?> Function()? read,
    Future<void> Function(String)? write,
  }) : _read = read ?? (() => SharedPreferencesAsync().getString(key)),
       _write =
           write ?? ((value) => SharedPreferencesAsync().setString(key, value));
  ThemePreferences.memory()
    : _read = (() async => null),
      _write = ((_) async {});
  static const key = 'aibs.theme-mode.v1';
  final Future<String?> Function() _read;
  final Future<void> Function(String) _write;
  ThemeMode mode = ThemeMode.system;
  bool saving = false;
  Future<void> load() async {
    final value = await _read();
    mode =
        ThemeMode.values.where((mode) => mode.name == value).firstOrNull ??
        ThemeMode.system;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode value) async {
    if (saving || mode == value) return;
    saving = true;
    notifyListeners();
    try {
      await _write(value.name);
      mode = value;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}

class ThemeSettings extends InheritedNotifier<ThemePreferences> {
  const ThemeSettings({
    super.key,
    required ThemePreferences preferences,
    required super.child,
  }) : super(notifier: preferences);
  static ThemePreferences? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeSettings>()?.notifier;
}
