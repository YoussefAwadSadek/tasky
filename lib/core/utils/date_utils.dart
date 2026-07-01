import 'package:intl/intl.dart';

/// Date helpers shared across tasks and habits.
///
/// All comparisons are done on the *calendar day* (year/month/day) so that a
/// task due at 23:59 still counts as "today" and a habit logged at any time on
/// a given day is treated as a single completion for that day.
class DateUtils {
  const DateUtils._();

  /// Strips the time component, returning midnight of [date].
  static DateTime dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Today at midnight.
  static DateTime today() => dayOnly(DateTime.now());

  /// Whether [a] and [b] fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whether [date] is today.
  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  /// Whether [date] is strictly after today (a future day).
  static bool isUpcoming(DateTime date) => dayOnly(date).isAfter(today());

  /// Whether [date] is strictly before today (an overdue day).
  static bool isOverdue(DateTime date) => dayOnly(date).isBefore(today());

  /// A friendly, human-readable label for a due date.
  ///
  /// Returns "Today", "Tomorrow", "Yesterday" for adjacent days and a short
  /// formatted date (e.g. "Mon, 23 Jun") otherwise.
  static String friendlyDate(DateTime date) {
    final DateTime day = dayOnly(date);
    final DateTime now = today();
    final int diff = day.difference(now).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(day);
  }

  /// Short weekday label such as "Mon".
  static String weekdayLabel(DateTime date) => DateFormat('EEE').format(date);

  /// Returns the seven days of the week containing [date], Monday first.
  static List<DateTime> weekOf(DateTime date) {
    final DateTime base = dayOnly(date);
    final DateTime monday = base.subtract(Duration(days: base.weekday - 1));
    return List<DateTime>.generate(7, (int i) => monday.add(Duration(days: i)));
  }

  /// Returns the last [count] days ending today (oldest first).
  static List<DateTime> lastDays(int count) {
    final DateTime now = today();
    return List<DateTime>.generate(
      count,
      (int i) => now.subtract(Duration(days: count - 1 - i)),
    );
  }
}
