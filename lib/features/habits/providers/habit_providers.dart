import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../model/habit.dart';
import '../repository/habit_repository.dart';

/// Provides the opened Hive box of habits (overridden in `main()`).
final habitBoxProvider = Provider<Box<Habit>>((ref) {
  return Hive.box<Habit>(AppConstants.habitsBox);
});

/// Provides the [HabitRepository].
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository(ref.watch(habitBoxProvider));
});

/// Owns the in-memory list of habits and all mutations.
class HabitListNotifier extends StateNotifier<List<Habit>> {
  HabitListNotifier(this._repository) : super(_repository.getAll());

  final HabitRepository _repository;
  static const Uuid _uuid = Uuid();

  Future<Habit> addHabit({
    required String title,
    String emoji = '⭐',
    required int colorValue,
  }) async {
    final Habit habit = Habit(
      id: _uuid.v4(),
      title: title.trim(),
      emoji: emoji,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    await _repository.add(habit);
    state = <Habit>[...state, habit];
    return habit;
  }

  Future<void> updateHabit(Habit habit) async {
    await _repository.update(habit);
    state = <Habit>[
      for (final Habit h in state) h.id == habit.id ? habit : h,
    ];
  }

  /// Toggles today's completion for the habit with [id].
  Future<void> toggleToday(String id) => toggleOn(id, DateTime.now());

  /// Toggles completion for [id] on the given [date].
  Future<void> toggleOn(String id, DateTime date) async {
    final int index = state.indexWhere((Habit h) => h.id == id);
    if (index == -1) return;
    final Habit updated = state[index].toggle(date);
    await _repository.update(updated);
    state = <Habit>[
      for (final Habit h in state) h.id == id ? updated : h,
    ];
  }

  /// Deletes a habit and returns it so the caller can offer an undo.
  Future<Habit?> deleteHabit(String id) async {
    final int index = state.indexWhere((Habit h) => h.id == id);
    if (index == -1) return null;
    final Habit removed = state[index];
    await _repository.delete(id);
    state = <Habit>[
      for (final Habit h in state)
        if (h.id != id) h,
    ];
    return removed;
  }

  Future<void> restore(Habit habit) async {
    await _repository.add(habit);
    state = <Habit>[...state, habit];
  }
}

final habitListProvider =
    StateNotifierProvider<HabitListNotifier, List<Habit>>((ref) {
  return HabitListNotifier(ref.watch(habitRepositoryProvider));
});

/// Looks up a single habit by id and stays in sync with the list.
final habitByIdProvider = Provider.family<Habit?, String>((ref, String id) {
  final List<Habit> habits = ref.watch(habitListProvider);
  for (final Habit h in habits) {
    if (h.id == id) return h;
  }
  return null;
});

/// Number of habits completed today (for the dashboard).
final habitsCompletedTodayProvider = Provider<int>((ref) {
  final List<Habit> habits = ref.watch(habitListProvider);
  return habits.where((Habit h) => h.isCompletedToday).length;
});

/// The window of stats shown on a habit's detail chart.
enum StatsRange {
  week,
  month;

  int get days => this == StatsRange.week ? 7 : 30;

  String get label => this == StatsRange.week ? 'Week' : 'Month';
}

/// A single bar in the completion chart.
class HabitBar {
  const HabitBar({
    required this.date,
    required this.completed,
  });

  final DateTime date;
  final bool completed;
}

/// Builds the chart data for one habit over the given [range].
///
/// Returns one [HabitBar] per day (oldest first) so the chart can render a
/// fixed number of evenly-spaced bars.
final habitStatsProvider =
    Provider.family<List<HabitBar>, ({String id, StatsRange range})>(
        (ref, ({String id, StatsRange range}) args) {
  final Habit? habit = ref.watch(habitByIdProvider(args.id));
  if (habit == null) return const <HabitBar>[];

  final List<DateTime> days = DateUtils.lastDays(args.range.days);
  return days
      .map(
        (DateTime d) => HabitBar(date: d, completed: habit.isCompletedOn(d)),
      )
      .toList();
});
