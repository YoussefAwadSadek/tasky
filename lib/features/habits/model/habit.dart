import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';

part 'habit.g.dart';

/// A repeatable daily habit the user checks off each day.
///
/// Completions are stored as a list of midnight [DateTime]s in
/// [completedDates]. Streaks and stats are derived on the fly from that list,
/// which keeps the stored data minimal and the logic easy to test.
@HiveType(typeId: AppConstants.habitTypeId)
class Habit extends HiveObject {
  Habit({
    required this.id,
    required this.title,
    this.emoji = '⭐',
    this.colorValue = 0xFF6750A4,
    required this.createdAt,
    List<DateTime>? completedDates,
  }) : completedDates = completedDates ?? <DateTime>[];

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String emoji;

  /// ARGB color value used for the habit's accent.
  @HiveField(3)
  final int colorValue;

  @HiveField(4)
  final DateTime createdAt;

  /// Midnight timestamps for each day the habit was completed.
  @HiveField(5)
  final List<DateTime> completedDates;

  Habit copyWith({
    String? title,
    String? emoji,
    int? colorValue,
    List<DateTime>? completedDates,
  }) {
    return Habit(
      id: id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  /// Whether the habit is marked done on [date]'s calendar day.
  bool isCompletedOn(DateTime date) =>
      completedDates.any((DateTime d) => DateUtils.isSameDay(d, date));

  /// Whether the habit is marked done today.
  bool get isCompletedToday => isCompletedOn(DateTime.now());

  /// Returns a copy with [date] toggled in [completedDates].
  Habit toggle(DateTime date) {
    final DateTime day = DateUtils.dayOnly(date);
    final List<DateTime> next = List<DateTime>.from(completedDates);
    final int index =
        next.indexWhere((DateTime d) => DateUtils.isSameDay(d, day));
    if (index >= 0) {
      next.removeAt(index);
    } else {
      next.add(day);
    }
    next.sort();
    return copyWith(completedDates: next);
  }

  /// The current streak: consecutive days completed ending today (or, if today
  /// is not yet done, ending yesterday so an unfinished day does not break it).
  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    final Set<int> days = completedDates
        .map((DateTime d) => DateUtils.dayOnly(d).millisecondsSinceEpoch)
        .toSet();

    DateTime cursor = DateUtils.today();
    if (!days.contains(cursor.millisecondsSinceEpoch)) {
      // Today not done yet — start counting from yesterday.
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor.millisecondsSinceEpoch)) return 0;
    }

    int streak = 0;
    while (days.contains(cursor.millisecondsSinceEpoch)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// The longest run of consecutive completed days in the habit's history.
  int get bestStreak {
    if (completedDates.isEmpty) return 0;

    final List<DateTime> sorted = completedDates
        .map(DateUtils.dayOnly)
        .toSet()
        .toList()
      ..sort();

    int best = 1;
    int run = 1;
    for (int i = 1; i < sorted.length; i++) {
      final int gap = sorted[i].difference(sorted[i - 1]).inDays;
      if (gap == 1) {
        run++;
        best = run > best ? run : best;
      } else {
        run = 1;
      }
    }
    return best;
  }

  /// Total number of distinct days the habit was completed.
  int get totalCompletions =>
      completedDates.map(DateUtils.dayOnly).toSet().length;

  @override
  String toString() => 'Habit($id, "$title", streak: $currentStreak)';
}
