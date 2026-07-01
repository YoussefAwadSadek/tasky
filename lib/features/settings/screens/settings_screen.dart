import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../habits/providers/habit_providers.dart';
import '../../tasks/providers/task_providers.dart';
import '../providers/settings_providers.dart';

/// Settings: theme mode, accent color, data management and an about section.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          const _SectionLabel('Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_rounded),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(settings.themeMode)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_rounded),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.settings_suggest_rounded),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_rounded),
                ),
              ],
              selected: <ThemeMode>{settings.themeMode},
              onSelectionChanged: (Set<ThemeMode> s) =>
                  notifier.setThemeMode(s.first),
            ),
          ),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.palette_rounded),
            title: Text('Accent color'),
            subtitle: Text('Used across buttons, charts and highlights'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                for (final Color color in AppTheme.accentSwatch)
                  _ColorDot(
                    color: color,
                    selected: color.toARGB32() ==
                        settings.accentColor.toARGB32(),
                    onTap: () => notifier.setAccentColor(color),
                  ),
              ],
            ),
          ),
          const Divider(height: 32),
          const _SectionLabel('Data'),
          ListTile(
            leading: Icon(
              Icons.delete_sweep_rounded,
              color: theme.colorScheme.error,
            ),
            title: const Text('Clear all data'),
            subtitle: const Text('Delete every task and habit (offline only)'),
            onTap: () => _confirmClear(context, ref),
          ),
          const Divider(height: 32),
          const _SectionLabel('About'),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text(AppConstants.appName),
            subtitle: Text(
              'Offline-first task & habit tracker.\n'
              'Built with Flutter, Riverpod & Hive.\nVersion 1.0.0',
            ),
            isThreeLine: true,
          ),
          const ListTile(
            leading: Icon(Icons.code_rounded),
            title: Text('Author'),
            subtitle: Text('Youssef Awad Sadek'),
          ),
          const ListTile(
            leading: Icon(Icons.cloud_off_rounded),
            title: Text('Works fully offline'),
            subtitle: Text('No account, no network, no tracking.'),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'Follow system',
      };

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This permanently deletes all tasks and habits. '
          'This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(taskRepositoryProvider).clear();
    await ref.read(habitRepositoryProvider).clear();
    // Reset in-memory state for both notifiers.
    ref.invalidate(taskListProvider);
    ref.invalidate(habitListProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('All data cleared')));
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
