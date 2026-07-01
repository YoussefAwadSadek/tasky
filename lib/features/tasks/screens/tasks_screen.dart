import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/empty_state.dart';
import '../model/task.dart';
import '../providers/task_providers.dart';
import '../widgets/task_editor_sheet.dart';
import '../widgets/task_tile.dart';

/// The main tasks screen: search, filter, sort and the task list itself.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        ref.read(taskSearchProvider.notifier).state = '';
      }
    });
  }

  void _deleteWithUndo(BuildContext context, Task task) {
    final TaskListNotifier notifier = ref.read(taskListProvider.notifier);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${task.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => notifier.restore(task),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Task> tasks = ref.watch(filteredTasksProvider);
    final TaskFilter filter = ref.watch(taskFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search tasks…',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (String value) =>
                    ref.read(taskSearchProvider.notifier).state = value,
              )
            : const Text('Tasks'),
        actions: <Widget>[
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search',
            icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: _toggleSearch,
          ),
          if (!_searching) const _SortMenu(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => TaskEditorSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add task'),
      ),
      body: Column(
        children: <Widget>[
          const _FilterBar(),
          if (filter == TaskFilter.completed && tasks.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: () =>
                      ref.read(taskListProvider.notifier).clearCompleted(),
                  icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                  label: const Text('Clear completed'),
                ),
              ),
            ),
          Expanded(
            child: tasks.isEmpty
                ? _buildEmpty(context, filter)
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 96),
                    itemCount: tasks.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Task task = tasks[index];
                      return TaskTile(
                        task: task,
                        onToggle: () => ref
                            .read(taskListProvider.notifier)
                            .toggleCompleted(task.id),
                        onDelete: () async {
                          await ref
                              .read(taskListProvider.notifier)
                              .deleteTask(task.id);
                          if (context.mounted) {
                            _deleteWithUndo(context, task);
                          }
                        },
                        onTap: () =>
                            TaskEditorSheet.show(context, task: task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, TaskFilter filter) {
    final String query = ref.read(taskSearchProvider);
    if (query.trim().isNotEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'No tasks match your search. Try a different keyword.',
      );
    }
    return switch (filter) {
      TaskFilter.completed => const EmptyState(
          icon: Icons.task_alt_rounded,
          title: 'Nothing completed yet',
          message: 'Finished tasks will show up here. Go check something off!',
        ),
      TaskFilter.today => const EmptyState(
          icon: Icons.wb_sunny_rounded,
          title: 'Nothing due today',
          message: 'Your day is clear. Add a task or enjoy the breather.',
        ),
      TaskFilter.upcoming => const EmptyState(
          icon: Icons.upcoming_rounded,
          title: 'No upcoming tasks',
          message: 'Plan ahead by adding a task with a future due date.',
        ),
      TaskFilter.all => EmptyState(
          icon: Icons.checklist_rounded,
          title: 'No tasks yet',
          message: 'Tap “Add task” to create your first one.',
          action: FilledButton.tonalIcon(
            onPressed: () => TaskEditorSheet.show(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add task'),
          ),
        ),
    };
  }
}

/// Horizontal scrolling filter chips bound to [taskFilterProvider].
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TaskFilter selected = ref.watch(taskFilterProvider);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: <Widget>[
          for (final TaskFilter filter in TaskFilter.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(filter.label),
                selected: selected == filter,
                onSelected: (_) =>
                    ref.read(taskFilterProvider.notifier).state = filter,
              ),
            ),
        ],
      ),
    );
  }
}

/// Popup menu that sets [taskSortProvider].
class _SortMenu extends ConsumerWidget {
  const _SortMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TaskSort current = ref.watch(taskSortProvider);
    return PopupMenuButton<TaskSort>(
      tooltip: 'Sort',
      icon: const Icon(Icons.sort_rounded),
      initialValue: current,
      onSelected: (TaskSort sort) =>
          ref.read(taskSortProvider.notifier).state = sort,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<TaskSort>>[
        for (final TaskSort sort in TaskSort.values)
          PopupMenuItem<TaskSort>(
            value: sort,
            child: Row(
              children: <Widget>[
                Icon(
                  current == sort
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(sort.label),
              ],
            ),
          ),
      ],
    );
  }
}
