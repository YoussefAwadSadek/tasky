import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/empty_state.dart';
import '../model/habit.dart';
import '../providers/habit_providers.dart';
import '../widgets/habit_editor_sheet.dart';
import '../widgets/habit_tile.dart';
import 'habit_detail_screen.dart';

/// Lists all habits with their streaks and a per-habit "done today" toggle.
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  void _openDetail(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HabitDetailScreen(habitId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Habit> habits = ref.watch(habitListProvider);
    final int doneToday = ref.watch(habitsCompletedTodayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        bottom: habits.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$doneToday of ${habits.length} done today',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => HabitEditorSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add habit'),
      ),
      body: habits.isEmpty
          ? EmptyState(
              icon: Icons.auto_awesome_rounded,
              title: 'Build a habit',
              message:
                  'Track daily routines and watch your streaks grow. Add your '
                  'first habit to get started.',
              action: FilledButton.tonalIcon(
                onPressed: () => HabitEditorSheet.show(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add habit'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 96),
              itemCount: habits.length,
              itemBuilder: (BuildContext context, int index) {
                final Habit habit = habits[index];
                return HabitTile(
                  habit: habit,
                  onToggleToday: () => ref
                      .read(habitListProvider.notifier)
                      .toggleToday(habit.id),
                  onTap: () => _openDetail(context, habit.id),
                );
              },
            ),
    );
  }
}
