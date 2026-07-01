import 'package:hive/hive.dart';

import '../model/habit.dart';

/// Persistence layer over the Hive [Box] that stores [Habit] objects.
///
/// Like [TaskRepository], it is UI- and Riverpod-agnostic so it can be tested
/// against an in-memory box.
class HabitRepository {
  HabitRepository(this._box);

  final Box<Habit> _box;

  List<Habit> getAll() => _box.values.toList(growable: false);

  Future<void> add(Habit habit) => _box.put(habit.id, habit);

  Future<void> update(Habit habit) => _box.put(habit.id, habit);

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();
}
