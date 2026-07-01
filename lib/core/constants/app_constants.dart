/// App-wide constant values: Hive box names, type ids and storage keys.
///
/// Keeping these in one place avoids typo-driven bugs (e.g. a misspelled box
/// name silently opening a second, empty box) and documents every Hive
/// `typeId` so adapters never collide.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Tasky';

  // ---- Hive box names ----
  static const String tasksBox = 'tasks_box';
  static const String habitsBox = 'habits_box';
  static const String settingsBox = 'settings_box';

  // ---- Hive type ids (must be unique across the whole app) ----
  static const int taskTypeId = 1;
  static const int priorityTypeId = 2;
  static const int habitTypeId = 3;

  // ---- Settings keys ----
  static const String themeModeKey = 'theme_mode';
  static const String accentColorKey = 'accent_color';
}
