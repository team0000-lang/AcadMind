import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.system);

Future<void> loadAppPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  appThemeMode.value = switch (prefs.getString('theme_mode') ?? 'system') {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

Future<void> saveThemeMode(ThemeMode mode) async {
  appThemeMode.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme_mode', switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  });
}
