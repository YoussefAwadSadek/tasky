import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart' as du;
import '../model/habit.dart';
import '../providers/habit_providers.dart';
import '../widgets/habit_editor_sheet.dart';
import '../widgets/habit_stats_chart.dart';

/// Detail screen for a single habit: stat cards, a completion chart and a
/// tappable week strip for back-filling missed days.
class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({required this.habitId, super.key});

  final String habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  StatsRange _range = StatsRange.week;

  @override
  Widget build(BuildContext context) {
    final Habit? habit = ref.watch(habitByIdProvider(widget.habitId));

    // The habit may have been deleted from elsewhere; pop gracefully.
    if (habit == null) {
      return const Scaffold(
        body: Center(child: Text('Habit not found')),
      );
    }

    final ThemeData theme = Theme.of(context);
    final Color color = Color(habit.colorValue);
    final List<HabitBar> bars = ref.watch(
      habitStatsProvider((id: habit.id, range: _range)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Text(habit.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(habit.title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => HabitEditorSheet.show(context, habit: habit),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(context, habit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.deepOrange,
                  value: '${habit.currentStreak}',
                  label: 'Current streak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.amber.shade700,
                  value: '${habit.bestStreak}',
                  label: 'Best streak',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_month_rounded,
                  iconColor: color,
                  value: '${habit.totalCompletions}',
                  label: 'Total days',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Completions',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              SegmentedButton<StatsRange>(
                segments: <ButtonSegment<StatsRange>>[
                  for (final StatsRange r in StatsRange.values)
                    ButtonSegment<StatsRange>(value: r, label: Text(r.label)),
                ],
                selected: <StatsRange>{_range},
                showSelectedIcon: false,
                onSelectionChanged: (Set<StatsRange> s) =>
                    setState(() => _range = s.first),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: HabitStatsChart(
              bars: bars,
              color: color,
              range: _range,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'This week',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _WeekStrip(habit: habit, color: color),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Habit habit) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text(
          'This will remove "${habit.title}" and its history. '
          'This cannot be undone here.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final Habit? removed =
        await ref.read(habitListProvider.notifier).deleteHabit(habit.id);

    if (!context.mounted || removed == null) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${removed.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () =>
                ref.read(habitListProvider.notifier).restore(removed),
          ),
        ),
      );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: <Widget>[
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A row of seven day-circles for the current week. Tapping toggles that day.
class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({required this.habit, required this.color});

  final Habit habit;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<DateTime> week = du.DateUtils.weekOf(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final DateTime day in week)
          Builder(
            builder: (BuildContext context) {
              final bool done = habit.isCompletedOn(day);
              final bool isFuture = du.DateUtils.isUpcoming(day);
              final bool isToday = du.DateUtils.isToday(day);

              return Column(
                children: <Widget>[
                  Text(
                    du.DateUtils.weekdayLabel(day),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Opacity(
                    opacity: isFuture ? 0.4 : 1,
                    child: InkWell(
                      onTap: isFuture
                          ? null
                          : () => ref
                              .read(habitListProvider.notifier)
                              .toggleOn(habit.id, day),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? color : Colors.transparent,
                          border: Border.all(
                            color: isToday
                                ? color
                                : theme.colorScheme.outlineVariant,
                            width: isToday ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: done
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
