import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../model/habit.dart';
import '../providers/habit_providers.dart';

/// A modal bottom sheet for creating or editing a [Habit].
class HabitEditorSheet extends ConsumerStatefulWidget {
  const HabitEditorSheet({this.habit, super.key});

  final Habit? habit;

  static Future<void> show(BuildContext context, {Habit? habit}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => HabitEditorSheet(habit: habit),
    );
  }

  @override
  ConsumerState<HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends ConsumerState<HabitEditorSheet> {
  static const List<String> _emojis = <String>[
    '⭐', '💧', '📚', '🏃', '🧘', '🥗', '💤', '🧠', '🎯', '✍️', '🎸', '🌱',
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late String _emoji;
  late Color _color;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final Habit? h = widget.habit;
    _titleController = TextEditingController(text: h?.title ?? '');
    _emoji = h?.emoji ?? _emojis.first;
    _color = h != null ? Color(h.colorValue) : AppTheme.accentSwatch.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final HabitListNotifier notifier = ref.read(habitListProvider.notifier);
    final String title = _titleController.text.trim();

    if (_isEditing) {
      await notifier.updateHabit(
        widget.habit!.copyWith(
          title: title,
          emoji: _emoji,
          colorValue: _color.toARGB32(),
        ),
      );
    } else {
      await notifier.addHabit(
        title: title,
        emoji: _emoji,
        colorValue: _color.toARGB32(),
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
                _isEditing ? 'Edit habit' : 'New habit',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Habit',
                  hintText: 'e.g. Drink water, Read 20 min',
                ),
                validator: (String? value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Please name your habit'
                        : null,
              ),
              const SizedBox(height: 16),
              Text('Icon', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final String e in _emojis)
                    _ChoiceCircle(
                      selected: e == _emoji,
                      onTap: () => setState(() => _emoji = e),
                      child: Text(e, style: const TextStyle(fontSize: 20)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Color', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final Color c in AppTheme.accentSwatch)
                    _ChoiceCircle(
                      selected: c.toARGB32() == _color.toARGB32(),
                      onTap: () => setState(() => _color = c),
                      child: CircleAvatar(radius: 12, backgroundColor: c),
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
                  label: Text(_isEditing ? 'Save changes' : 'Add habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCircle extends StatelessWidget {
  const _ChoiceCircle({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: child,
      ),
    );
  }
}
