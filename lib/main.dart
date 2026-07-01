import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'features/habits/model/habit.dart';
import 'features/habits/providers/habit_providers.dart';
import 'features/settings/providers/settings_providers.dart';
import 'features/tasks/model/priority.dart';
import 'features/tasks/model/task.dart';
import 'features/tasks/providers/task_providers.dart';

/// App entry point.
///
/// Hive must be initialized, its adapters registered, and every box opened
/// *before* `runApp`, because the providers read the boxes synchronously. The
/// opened boxes are then injected into Riverpod via `overrideWithValue`, which
/// keeps the rest of the app free of async box look-ups.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter (resolves a platform-appropriate directory).
  await Hive.initFlutter();

  // Register adapters exactly once. Guarding on isAdapterRegistered makes the
  // call idempotent, which matters for hot restart and widget tests.
  if (!Hive.isAdapterRegistered(AppConstants.taskTypeId)) {
    Hive.registerAdapter(TaskAdapter());
  }
  if (!Hive.isAdapterRegistered(AppConstants.priorityTypeId)) {
    Hive.registerAdapter(PriorityAdapter());
  }
  if (!Hive.isAdapterRegistered(AppConstants.habitTypeId)) {
    Hive.registerAdapter(HabitAdapter());
  }

  // Open all boxes up front.
  final Box<Task> taskBox = await Hive.openBox<Task>(AppConstants.tasksBox);
  final Box<Habit> habitBox =
      await Hive.openBox<Habit>(AppConstants.habitsBox);
  final Box<dynamic> settingsBox =
      await Hive.openBox<dynamic>(AppConstants.settingsBox);

  runApp(
    ProviderScope(
      overrides: <Override>[
        taskBoxProvider.overrideWithValue(taskBox),
        habitBoxProvider.overrideWithValue(habitBox),
        settingsBoxProvider.overrideWithValue(settingsBox),
      ],
      child: const TaskyApp(),
    ),
  );
}
