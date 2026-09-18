import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemePreferencesRepository {
  const ThemePreferencesRepository();

  Future<ThemeMode?> loadThemeMode();

  Future<void> saveThemeMode(ThemeMode themeMode);

  Future<bool?> loadSidebarCollapsed();

  Future<void> saveSidebarCollapsed(bool isCollapsed);
}

class SharedPreferencesThemePreferencesRepository
    implements ThemePreferencesRepository {
  const SharedPreferencesThemePreferencesRepository();

  static const String _themeModeKey = 'app_theme_mode';
  static const String _sidebarCollapsedKey = 'dashboard_sidebar_collapsed';

  @override
  Future<ThemeMode?> loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final savedValue = preferences.getString(_themeModeKey);

    return switch (savedValue) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => null,
    };
  }

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, switch (themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  @override
  Future<bool?> loadSidebarCollapsed() async {
    final preferences = await SharedPreferences.getInstance();
    if (!preferences.containsKey(_sidebarCollapsedKey)) {
      return null;
    }

    return preferences.getBool(_sidebarCollapsedKey);
  }

  @override
  Future<void> saveSidebarCollapsed(bool isCollapsed) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_sidebarCollapsedKey, isCollapsed);
  }
}
