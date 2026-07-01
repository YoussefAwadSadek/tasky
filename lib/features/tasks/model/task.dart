import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';
import 'priority.dart';

part 'task.g.dart';

/// A single to-do item.
///
/// Tasks are immutable in spirit: state changes are made through [copyWith],
/// which returns a fresh instance. This keeps Riverpod's equality checks
/// predictable and avoids accidental in-place mutation of objects still held
/// inside a Hive box.
@HiveType(typeId: AppConstants.taskTypeId)
class Task extends HiveObject {
  Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.category = 'General',
    this.priority = Priority.medium,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String notes;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final Priority priority;

  @HiveField(5)
  final DateTime? dueDate;

  @HiveField(6)
  final bool isCompleted;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? completedAt;

  Task copyWith({
    String? title,
    String? notes,
    String? category,
    Priority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  /// Returns a toggled copy, stamping or clearing [completedAt] accordingly.
  Task toggleCompleted() {
    final bool next = !isCompleted;
    return copyWith(
      isCompleted: next,
      completedAt: next ? DateTime.now() : null,
      clearCompletedAt: !next,
    );
  }

  @override
  String toString() => 'Task($id, "$title", completed: $isCompleted)';
}
