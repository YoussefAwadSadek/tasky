import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';

part 'priority.g.dart';

/// Task priority levels, ordered from least to most urgent.
///
/// Persisted with a generated [HiveType] adapter (see `priority.g.dart`,
/// produced by `dart run build_runner build`).
@HiveType(typeId: AppConstants.priorityTypeId)
enum Priority {
  @HiveField(0)
  low,

  @HiveField(1)
  medium,

  @HiveField(2)
  high;

  /// Human-readable label.
  String get label => switch (this) {
        Priority.low => 'Low',
        Priority.medium => 'Medium',
        Priority.high => 'High',
      };

  /// Color used for badges and accents.
  Color get color => switch (this) {
        Priority.low => const Color(0xFF2E7D32),
        Priority.medium => const Color(0xFFEF6C00),
        Priority.high => const Color(0xFFC62828),
      };

  IconData get icon => switch (this) {
        Priority.low => Icons.arrow_downward_rounded,
        Priority.medium => Icons.drag_handle_rounded,
        Priority.high => Icons.priority_high_rounded,
      };
}
