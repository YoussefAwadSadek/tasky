import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tasky/app.dart';
import 'package:tasky/core/constants/app_constants.dart';
import 'package:tasky/features/habits/model/habit.dart';
import 'package:tasky/features/habits/providers/habit_providers.dart';
import 'package:tasky/features/settings/providers/settings_providers.dart';
import 'package:tasky/features/tasks/model/priority.dart';
import 'package:tasky/features/tasks/model/task.dart';
import 'package:tasky/features/tasks/providers/task_providers.dart';
import 'package:tasky/features/tasks/widgets/task_editor_sheet.dart';

/// A widget smoke test that boots the whole app against temporary Hive boxes
/// and verifies the bottom navigation and empty states render.
void main() {
  late Directory tempDir;
  late Box<Task> taskBox;
  late Box<Habit> habitBox;
  late Box<dynamic> settingsBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tasky_widget_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(AppConstants.taskTypeId)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.priorityTypeId)) {
      Hive.registerAdapter(PriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.habitTypeId)) {
      Hive.registerAdapter(HabitAdapter());
    }

    taskBox = await Hive.openBox<Task>(AppConstants.tasksBox);
    habitBox = await Hive.openBox<Habit>(AppConstants.habitsBox);
    settingsBox = await Hive.openBox<dynamic>(AppConstants.settingsBox);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: <Override>[
        taskBoxProvider.overrideWithValue(taskBox),
        habitBoxProvider.overrideWithValue(habitBox),
        settingsBoxProvider.overrideWithValue(settingsBox),
      ],
      child: const TaskyApp(),
    );
  }

  testWidgets('boots to the home dashboard with all nav tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Greeting on the dashboard (time-dependent, so match the prefix).
    expect(find.textContaining('Good'), findsOneWidget);

    // The Material 3 NavigationBar with its four destinations is present.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget); // selected Home
    expect(find.byIcon(Icons.checklist_outlined), findsOneWidget); // Tasks
    expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget); // Habits
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget); // Settings
  });

  testWidgets('tasks tab shows the empty state then adds a task', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Navigate to the Tasks tab via its NavigationBar icon (unambiguous).
    await tester.tap(find.byIcon(Icons.checklist_outlined));
    await tester.pumpAndSettle();

    // The empty state for an unfiltered, empty task list is shown.
    expect(find.text('No tasks yet'), findsOneWidget);

    // Open the editor via the extended FAB (its label is unique on this tab).
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Fill in a title.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'What needs doing?'),
      'Buy milk',
    );

    // Tap the editor's "Add task" button, scoped to the bottom sheet so it is
    // not confused with the empty-state button on the screen behind it.
    final Finder saveButton = find.descendant(
      of: find.byType(TaskEditorSheet),
      matching: find.widgetWithText(FilledButton, 'Add task'),
    );
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // The new task appears and the empty state is gone.
    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('No tasks yet'), findsNothing);
  });
}
