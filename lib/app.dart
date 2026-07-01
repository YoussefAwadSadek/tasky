import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/home_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_providers.dart';

/// The root widget. Rebuilds [MaterialApp] whenever the user changes the theme
/// mode or accent color, so settings apply instantly and live across restarts.
class TaskyApp extends ConsumerWidget {
  const TaskyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.accentColor),
      darkTheme: AppTheme.dark(settings.accentColor),
      themeMode: settings.themeMode,
      home: const HomeShell(),
    );
  }
}
