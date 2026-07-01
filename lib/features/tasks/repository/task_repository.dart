import 'package:hive/hive.dart';

import '../model/task.dart';

/// Thin persistence layer over the Hive [Box] that stores [Task] objects.
///
/// The repository deliberately knows nothing about Riverpod or the UI; it only
/// reads and writes Hive. This makes it trivially unit-testable against an
/// in-memory box and keeps state-management concerns in the providers layer.
class TaskRepository {
  TaskRepository(this._box);

  final Box<Task> _box;

  /// All tasks currently stored, in insertion order.
  List<Task> getAll() => _box.values.toList(growable: false);

  /// Inserts a new task, keyed by its [Task.id].
  Future<void> add(Task task) => _box.put(task.id, task);

  /// Replaces an existing task (same [Task.id]) with [task].
  Future<void> update(Task task) => _box.put(task.id, task);

  /// Removes the task with the given [id].
  Future<void> delete(String id) => _box.delete(id);

  /// Removes every task. Used by "clear all" in Settings.
  Future<void> clear() => _box.clear();
}
