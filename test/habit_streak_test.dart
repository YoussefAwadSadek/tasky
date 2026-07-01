import 'package:flutter_test/flutter_test.dart';
import 'package:tasky/features/habits/model/habit.dart';

/// Unit tests for the pure streak/stat logic on [Habit].
///
/// These run without Hive or Flutter bindings because the streak getters work
/// purely off the in-memory [Habit.completedDates] list.
void main() {
  DateTime day(int daysAgo) {
    final DateTime now = DateTime.now();
    final DateTime base = DateTime(now.year, now.month, now.day);
    return base.subtract(Duration(days: daysAgo));
  }

  Habit habitWith(List<DateTime> dates) => Habit(
        id: 'h1',
        title: 'Test habit',
        createdAt: DateTime(2024, 1, 1),
        completedDates: dates,
      );

  group('currentStreak', () {
    test('is 0 with no completions', () {
      expect(habitWith(<DateTime>[]).currentStreak, 0);
    });

    test('counts today plus consecutive prior days', () {
      final Habit habit = habitWith(<DateTime>[day(0), day(1), day(2)]);
      expect(habit.currentStreak, 3);
    });

    test('still counts yesterday-anchored streak when today is not done', () {
      final Habit habit = habitWith(<DateTime>[day(1), day(2)]);
      expect(habit.currentStreak, 2);
    });

    test('resets when a day is missed', () {
      // Today and 3 days ago, but yesterday and 2 days ago are missing.
      final Habit habit = habitWith(<DateTime>[day(0), day(3)]);
      expect(habit.currentStreak, 1);
    });
  });

  group('bestStreak', () {
    test('finds the longest historical run', () {
      final Habit habit = habitWith(<DateTime>[
        day(10), day(9), day(8), // run of 3
        day(5), // isolated
        day(2), day(1), day(0), // run of 3 ending today
      ]);
      expect(habit.bestStreak, 3);
    });

    test('is 1 for a single completion', () {
      expect(habitWith(<DateTime>[day(4)]).bestStreak, 1);
    });
  });

  group('totalCompletions & toggle', () {
    test('counts distinct days only', () {
      final Habit habit = habitWith(<DateTime>[day(0), day(0), day(1)]);
      expect(habit.totalCompletions, 2);
    });

    test('toggle adds then removes a day', () {
      Habit habit = habitWith(<DateTime>[]);
      expect(habit.isCompletedToday, isFalse);

      habit = habit.toggle(DateTime.now());
      expect(habit.isCompletedToday, isTrue);
      expect(habit.totalCompletions, 1);

      habit = habit.toggle(DateTime.now());
      expect(habit.isCompletedToday, isFalse);
      expect(habit.totalCompletions, 0);
    });
  });
}
