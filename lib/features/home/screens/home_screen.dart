import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../habits/model/habit.dart';
import '../../habits/providers/habit_providers.dart';
import '../../habits/widgets/habit_editor_sheet.dart';
import '../../tasks/model/task.dart';
import '../../tasks/providers/task_providers.dart';
import '../../tasks/widgets/task_editor_sheet.dart';
import '../widgets/progress_ring.dart';

/// The home dashboard: a greeting, today's progress ring, quick-add buttons,
/// today's tasks and a quick habit check-off strip.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final TaskSummary summary = ref.watch(taskSummaryProvider);
    final List<Task> todayTasks = ref.watch(todayTasksProvider);
    final List<Habit> habits = ref.watch(habitListProvider);
    final int habitsDone = ref.watch(habitsCompletedTodayProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: <Widget>[
            Text(
              _greeting(),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              DateFormat('EEEE, d MMMM').format(DateTime.now()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              summary: summary,
              habitsDone: habitsDone,
              habitsTotal: habits.length,
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: _QuickAddButton(
                    icon: Icons.add_task_rounded,
                    label: 'New task',
                    onTap: () => TaskEditorSheet.show(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAddButton(
                    icon: Icons.auto_awesome_rounded,
                    label: 'New habit',
                    onTap: () => HabitEditorSheet.show(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Today’s tasks',
              trailing: '${todayTasks.length}',
            ),
            const SizedBox(height: 8),
            if (todayTasks.isEmpty)
              const _MutedCard(
                icon: Icons.wb_sunny_rounded,
                text: 'No tasks due today. Add one or enjoy a clear day.',
              )
            else
              ...todayTasks.map(
                (Task task) => _TodayTaskRow(
                  task: task,
                  onToggle: () => ref
                      .read(taskListProvider.notifier)
                      .toggleCompleted(task.id),
                ),
              ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Habits',
              trailing: '$habitsDone/${habits.length}',
            ),
            const SizedBox(height: 8),
            if (habits.isEmpty)
              const _MutedCard(
                icon: Icons.auto_awesome_rounded,
                text: 'No habits yet. Create one to start a streak.',
              )
            else
              _HabitQuickRow(habits: habits),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.habitsDone,
    required this.habitsTotal,
  });

  final TaskSummary summary;
  final int habitsDone;
  final int habitsTotal;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: <Widget>[
            ProgressRing(progress: summary.progress),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _StatLine(
                    icon: Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    text:
                        '${summary.completed} of ${summary.total} tasks done',
                  ),
                  const SizedBox(height: 10),
                  _StatLine(
                    icon: Icons.today_rounded,
                    color: theme.colorScheme.tertiary,
                    text: '${summary.dueToday} due today',
                  ),
                  const SizedBox(height: 10),
                  _StatLine(
                    icon: Icons.error_outline_rounded,
                    color: theme.colorScheme.error,
                    text: '${summary.overdue} overdue',
                  ),
                  const SizedBox(height: 10),
                  _StatLine(
                    icon: Icons.local_fire_department_rounded,
                    color: Colors.deepOrange,
                    text: '$habitsDone of $habitsTotal habits today',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          trailing,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MutedCard extends StatelessWidget {
  const _MutedCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayTaskRow extends StatelessWidget {
  const _TodayTaskRow({required this.task, required this.onToggle});

  final Task task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggle(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
        trailing: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: task.priority.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _HabitQuickRow extends ConsumerWidget {
  const _HabitQuickRow({required this.habits});

  final List<Habit> habits;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: habits.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final Habit habit = habits[index];
          final Color color = Color(habit.colorValue);
          final bool done = habit.isCompletedToday;
          return InkWell(
            onTap: () =>
                ref.read(habitListProvider.notifier).toggleToday(habit.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 84,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: done
                    ? color.withValues(alpha: 0.16)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.4),
                border: Border.all(
                  color: done ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(habit.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
