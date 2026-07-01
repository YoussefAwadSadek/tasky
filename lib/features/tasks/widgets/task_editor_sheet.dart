import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart' as du;
import '../model/priority.dart';
import '../model/task.dart';
import '../providers/task_providers.dart';

/// A modal bottom sheet for creating or editing a [Task].
///
/// Pass an existing [task] to edit it; pass `null` to create a new one. Returns
/// nothing — it writes directly through [taskListProvider].
class TaskEditorSheet extends ConsumerStatefulWidget {
  const TaskEditorSheet({this.task, super.key});

  final Task? task;

  /// Convenience launcher that wires up the rounded modal sheet.
  static Future<void> show(BuildContext context, {Task? task}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => TaskEditorSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends ConsumerState<TaskEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _categoryController;
  late Priority _priority;
  DateTime? _dueDate;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final Task? t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _categoryController =
        TextEditingController(text: t?.category ?? 'General');
    _priority = t?.priority ?? Priority.medium;
    _dueDate = t?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final TaskListNotifier notifier = ref.read(taskListProvider.notifier);
    final String title = _titleController.text.trim();
    final String notes = _notesController.text.trim();
    final String category = _categoryController.text.trim();

    if (_isEditing) {
      await notifier.updateTask(
        widget.task!.copyWith(
          title: title,
          notes: notes,
          category: category.isEmpty ? 'General' : category,
          priority: _priority,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        ),
      );
    } else {
      await notifier.addTask(
        title: title,
        notes: notes,
        category: category,
        priority: _priority,
        dueDate: _dueDate,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _isEditing ? 'Edit task' : 'New task',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What needs doing?',
                ),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please enter a title'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add details…',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'e.g. Work, Study, Personal',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Text('Priority', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<Priority>(
                segments: <ButtonSegment<Priority>>[
                  for (final Priority p in Priority.values)
                    ButtonSegment<Priority>(
                      value: p,
                      label: Text(p.label),
                      icon: Icon(p.icon),
                    ),
                ],
                selected: <Priority>{_priority},
                onSelectionChanged: (Set<Priority> selection) =>
                    setState(() => _priority = selection.first),
              ),
              const SizedBox(height: 16),
              Text('Due date', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDueDate,
                      icon: const Icon(Icons.event_rounded),
                      label: Text(
                        _dueDate == null
                            ? 'No due date'
                            : du.DateUtils.friendlyDate(_dueDate!),
                      ),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_dueDate != null)
                    IconButton(
                      tooltip: 'Clear due date',
                      onPressed: () => setState(() => _dueDate = null),
                      icon: const Icon(Icons.clear_rounded),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(
                    _isEditing ? Icons.save_rounded : Icons.add_rounded,
                  ),
                  label: Text(_isEditing ? 'Save changes' : 'Add task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
