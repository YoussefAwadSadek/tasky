import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// Provides the lightweight key/value settings box (overridden in `main()`).
///
/// Uses a dynamic box because it stores heterogeneous primitives (an int for
/// the theme mode, an int for the accent color, etc.).
final settingsBoxProvider = Provider<Box<dynamic>>((ref) {
  return Hive.box<dynamic>(AppConstants.settingsBox);
});

/// Immutable snapshot of user preferences.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.accentColor,
  });

  final ThemeMode themeMode;
  final Color accentColor;

  AppSettings copyWith({ThemeMode? themeMode, Color? accentColor}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

/// Persists and exposes the user's theme preferences.
///
/// Reads its initial value from Hive on construction and writes back on every
/// change, so the chosen theme and accent survive an app restart.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._box) : super(_read(_box));

  final Box<dynamic> _box;

  static AppSettings _read(Box<dynamic> box) {
    final int themeIndex = box.get(
      AppConstants.themeModeKey,
      defaultValue: ThemeMode.system.index,
    ) as int;
    final int accentValue = box.get(
      AppConstants.accentColorKey,
      defaultValue: AppTheme.defaultAccent.toARGB32(),
    ) as int;

    final int safeIndex =
        themeIndex.clamp(0, ThemeMode.values.length - 1).toInt();

    return AppSettings(
      themeMode: ThemeMode.values[safeIndex],
      accentColor: Color(accentValue),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _box.put(AppConstants.themeModeKey, mode.index);
  }

  Future<void> setAccentColor(Color color) async {
    state = state.copyWith(accentColor: color);
    await _box.put(AppConstants.accentColorKey, color.toARGB32());
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsBoxProvider));
});
