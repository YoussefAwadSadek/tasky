import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../model/priority.dart';
import '../model/task.dart';
import '../repository/task_repository.dart';

/// Provides the opened Hive box of tasks.
///
/// Overridden in `main()` with the already-open box so the rest of the app can
/// read it synchronously. The fallback `Hive.box` keeps tests honest if they
/// open the box themselves.
final taskBoxProvider = Provider<Box<Task>>((ref) {
  return Hive.box<Task>(AppConstants.tasksBox);
});

/// Provides the [TaskRepository] built on top of the box.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(taskBoxProvider));
});

/// The available filters for the task list.
enum TaskFilter {
  all,
  today,
  upcoming,
  completed;

  String get label => switch (this) {
        TaskFilter.all => 'All',
        TaskFilter.today => 'Today',
        TaskFilter.upcoming => 'Upcoming',
        TaskFilter.completed => 'Completed',
      };
}

/// How the visible task list is ordered.
enum TaskSort {
  dueDate,
  priority,
  created,
  alphabetical;

  String get label => switch (this) {
        TaskSort.dueDate => 'Due date',
        TaskSort.priority => 'Priority',
        TaskSort.created => 'Newest',
        TaskSort.alphabetical => 'A → Z',
      };
}

/// Current filter selection (UI state).
final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

/// Current sort selection (UI state).
final taskSortProvider = StateProvider<TaskSort>((ref) => TaskSort.dueDate);

/// Current search query (UI state).
final taskSearchProvider = StateProvider<String>((ref) => '');

/// Owns the canonical, in-memory list of tasks and all mutations.
///
/// Every write goes through the repository (Hive) first and then updates the
/// notifier's state, so persistence and UI never drift apart.
class TaskListNotifier extends StateNotifier<List<Task>> {
  TaskListNotifier(this._repository) : super(_repository.getAll());

  final TaskRepository _repository;
  static const Uuid _uuid = Uuid();

  /// Creates and persists a new task, returning the created instance.
  Future<Task> addTask({
    required String title,
    String notes = '',
    String category = 'General',
    Priority priority = Priority.medium,
    DateTime? dueDate,
  }) async {
    final Task task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      notes: notes.trim(),
      category: category.trim().isEmpty ? 'General' : category.trim(),
      priority: priority,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    await _repository.add(task);
    state = <Task>[...state, task];
    return task;
  }

  /// Persists an edited task in place.
  Future<void> updateTask(Task task) async {
    await _repository.update(task);
    state = <Task>[
      for (final Task t in state) t.id == task.id ? task : t,
    ];
  }

  /// Toggles completion for the task with [id].
  Future<void> toggleCompleted(String id) async {
    final int index = state.indexWhere((Task t) => t.id == id);
    if (index == -1) return;
    final Task updated = state[index].toggleCompleted();
    await _repository.update(updated);
    state = <Task>[
      for (final Task t in state) t.id == id ? updated : t,
    ];
  }

  /// Deletes a task and returns it so the caller can offer an undo.
  Future<Task?> deleteTask(String id) async {
    final int index = state.indexWhere((Task t) => t.id == id);
    if (index == -1) return null;
    final Task removed = state[index];
    await _repository.delete(id);
    state = <Task>[
      for (final Task t in state)
        if (t.id != id) t,
    ];
    return removed;
  }

  /// Re-inserts a previously deleted task (used by the undo snackbar).
  Future<void> restore(Task task) async {
    await _repository.add(task);
    state = <Task>[...state, task];
  }

  /// Removes every completed task.
  Future<void> clearCompleted() async {
    final List<Task> completed =
        state.where((Task t) => t.isCompleted).toList();
    for (final Task t in completed) {
      await _repository.delete(t.id);
    }
    state = state.where((Task t) => !t.isCompleted).toList();
  }
}

/// The notifier provider exposing the raw, unfiltered task list.
final taskListProvider =
    StateNotifierProvider<TaskListNotifier, List<Task>>((ref) {
  return TaskListNotifier(ref.watch(taskRepositoryProvider));
});

/// The task list after applying the active filter, search and sort.
///
/// Derived state: any change to the underlying list or to a UI selection
/// recomputes this automatically.
final filteredTasksProvider = Provider<List<Task>>((ref) {
  final List<Task> tasks = ref.watch(taskListProvider);
  final TaskFilter filter = ref.watch(taskFilterProvider);
  final TaskSort sort = ref.watch(taskSortProvider);
  final String query = ref.watch(taskSearchProvider).trim().toLowerCase();

  Iterable<Task> result = tasks;

  result = switch (filter) {
    TaskFilter.all => result,
    TaskFilter.today => result.where(
        (Task t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            DateUtils.isToday(t.dueDate!),
      ),
    TaskFilter.upcoming => result.where(
        (Task t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            DateUtils.isUpcoming(t.dueDate!),
      ),
    TaskFilter.completed => result.where((Task t) => t.isCompleted),
  };

  if (query.isNotEmpty) {
    result = result.where(
      (Task t) =>
          t.title.toLowerCase().contains(query) ||
          t.notes.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query),
    );
  }

  final List<Task> sorted = result.toList();
  sorted.sort((Task a, Task b) {
    switch (sort) {
      case TaskSort.dueDate:
        // Tasks without a due date sink to the bottom.
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      case TaskSort.priority:
        return b.priority.index.compareTo(a.priority.index);
      case TaskSort.created:
        return b.createdAt.compareTo(a.createdAt);
      case TaskSort.alphabetical:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
  });
  return sorted;
});

/// Tasks due today and not yet completed (used by the home dashboard).
final todayTasksProvider = Provider<List<Task>>((ref) {
  final List<Task> tasks = ref.watch(taskListProvider);
  return tasks
      .where(
        (Task t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            DateUtils.isToday(t.dueDate!),
      )
      .toList();
});

/// A small immutable summary used by the dashboard progress ring.
class TaskSummary {
  const TaskSummary({
    required this.total,
    required this.completed,
    required this.dueToday,
    required this.overdue,
  });

  final int total;
  final int completed;
  final int dueToday;
  final int overdue;

  /// Completion ratio in `[0, 1]`. Returns 0 when there are no tasks.
  double get progress => total == 0 ? 0 : completed / total;
}

/// Aggregate counts across all tasks for the home dashboard.
final taskSummaryProvider = Provider<TaskSummary>((ref) {
  final List<Task> tasks = ref.watch(taskListProvider);
  final int completed = tasks.where((Task t) => t.isCompleted).length;
  final int dueToday = tasks
      .where(
        (Task t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            DateUtils.isToday(t.dueDate!),
      )
      .length;
  final int overdue = tasks
      .where(
        (Task t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            DateUtils.isOverdue(t.dueDate!),
      )
      .length;
  return TaskSummary(
    total: tasks.length,
    completed: completed,
    dueToday: dueToday,
    overdue: overdue,
  );
});
