import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tasky/core/constants/app_constants.dart';
import 'package:tasky/features/tasks/model/priority.dart';
import 'package:tasky/features/tasks/model/task.dart';
import 'package:tasky/features/tasks/repository/task_repository.dart';

/// Repository-level tests against a temporary on-disk Hive instance.
///
/// We point Hive at a throwaway temp directory in [setUp] and delete it in
/// [tearDown], so the tests need no extra packages and never touch real app
/// storage. The pure domain logic is additionally covered in
/// `habit_streak_test.dart`.
void main() {
  late Directory tempDir;
  late Box<Task> box;
  late TaskRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tasky_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(AppConstants.taskTypeId)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.priorityTypeId)) {
      Hive.registerAdapter(PriorityAdapter());
    }
    box = await Hive.openBox<Task>(AppConstants.tasksBox);
    repository = TaskRepository(box);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Task makeTask(String id, String title) => Task(
        id: id,
        title: title,
        priority: Priority.high,
        createdAt: DateTime.now(),
      );

  test('add then getAll returns the task', () async {
    await repository.add(makeTask('1', 'Write tests'));
    final List<Task> all = repository.getAll();
    expect(all, hasLength(1));
    expect(all.single.title, 'Write tests');
    expect(all.single.priority, Priority.high);
  });

  test('update replaces the existing task by id', () async {
    final Task task = makeTask('1', 'Original');
    await repository.add(task);
    await repository.update(task.copyWith(title: 'Edited'));

    final List<Task> all = repository.getAll();
    expect(all, hasLength(1));
    expect(all.single.title, 'Edited');
  });

  test('delete removes only the matching task', () async {
    await repository.add(makeTask('1', 'Keep'));
    await repository.add(makeTask('2', 'Remove'));
    await repository.delete('2');

    final List<Task> all = repository.getAll();
    expect(all, hasLength(1));
    expect(all.single.id, '1');
  });

  test('toggleCompleted stamps and clears completedAt', () {
    final Task task = makeTask('1', 'Task');
    expect(task.isCompleted, isFalse);
    expect(task.completedAt, isNull);

    final Task done = task.toggleCompleted();
    expect(done.isCompleted, isTrue);
    expect(done.completedAt, isNotNull);

    final Task undone = done.toggleCompleted();
    expect(undone.isCompleted, isFalse);
    expect(undone.completedAt, isNull);
  });
}
