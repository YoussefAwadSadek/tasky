# Tasky

> An offline-first, cross-platform task & habit tracker built with Flutter, Riverpod and Hive.

Tasky helps you plan your day and build lasting routines — completely offline. There is no account, no network call and no tracking: everything lives in a local encrypted-on-disk Hive store, so the app is fast, private and works on a plane. It is built with a clean, **feature-first** architecture and a polished **Material 3** design.

---

## Features

### Tasks
- Add, edit, delete and complete tasks with **title, notes, category/tag, priority and due date**.
- **Filter** by `All` / `Today` / `Upcoming` / `Completed`.
- **Search** across titles, notes and categories.
- **Sort** by due date, priority, newest, or alphabetically.
- **Swipe-to-complete** (swipe right) and **swipe-to-delete** (swipe left).
- **Undo on delete** via a snackbar action.
- One-tap **"clear completed"**.

### Habits
- Create habits with an emoji icon and accent color.
- **Mark done per day** from the home screen, the list, or the week strip.
- Automatic **current streak** and **best streak** tracking.
- A **weekly / monthly completion bar chart** powered by `fl_chart`.
- Back-fill any missed day in the current week by tapping it.

### Home dashboard
- Time-aware greeting and today's date.
- **Progress ring** showing overall task completion.
- At-a-glance counts: done, due today, overdue, and habits completed today.
- **Quick add** for tasks and habits.
- Today's tasks list and a horizontal habit check-off strip.

### Settings
- **Light / Dark / System** theme toggle — **persisted** across restarts.
- **Accent color** picker that re-themes the whole app (including charts).
- **Clear all data** with confirmation.
- About section.

### UX polish
- Friendly **empty states** everywhere (no data, no search results, nothing due).
- **Snackbars with undo**, smooth animated progress ring and toggle buttons.
- Fully **offline** — seeded with no data, but every empty state is handled gracefully.

---

## Screenshots

> _Placeholder._ Run the app and drop screenshots into a `screenshots/` folder, then reference them here, e.g.:
>
> | Home | Tasks | Habits | Habit stats |
> |------|-------|--------|-------------|
> | ![Home](screenshots/home.png) | ![Tasks](screenshots/tasks.png) | ![Habits](screenshots/habits.png) | ![Stats](screenshots/stats.png) |

---

## Tech stack

| Concern | Choice |
|---|---|
| Framework | **Flutter** (Material 3) |
| Language | **Dart** (null-safe, SDK ≥ 3.3) |
| State management | **flutter_riverpod** (`StateNotifier` + derived `Provider`s) |
| Local persistence | **hive** + **hive_flutter** (offline, no backend) |
| Charts | **fl_chart** |
| Dates / formatting | **intl** |
| Typography | **google_fonts** (Inter) |
| Ids | **uuid** |
| Lints | **flutter_lints** |
| Codegen (adapters) | **hive_generator** + **build_runner** |

---

## Architecture

Tasky uses a **feature-first** layout. Each feature owns its model, repository, providers, screens and widgets, and depends only on the shared `core/` layer:

```
lib/
├── main.dart                 # Hive init, adapter registration, box opening, ProviderScope overrides
├── app.dart                  # MaterialApp; reacts to theme/accent settings
├── core/
│   ├── constants/            # Box names, Hive typeIds, settings keys
│   ├── router/               # HomeShell (Material 3 NavigationBar + IndexedStack)
│   ├── theme/                # ColorScheme.fromSeed light/dark themes
│   └── utils/                # Date helpers, reusable EmptyState widget
└── features/
    ├── home/                 # Dashboard: progress ring, summary, quick add
    ├── tasks/
    │   ├── model/            # Task, Priority (+ committed .g.dart adapters)
    │   ├── repository/       # TaskRepository over a Hive Box
    │   ├── providers/        # taskListProvider, filtered/sorted/derived providers
    │   ├── screens/          # TasksScreen
    │   └── widgets/          # TaskTile (swipe), TaskEditorSheet, PriorityBadge
    ├── habits/               # Same shape: model/repo/providers/screens/widgets + chart
    └── settings/             # Persisted theme & accent providers + screen
```

**Data flow.** The UI never touches Hive directly. Widgets watch Riverpod providers → providers call a `StateNotifier` → the notifier writes through a `Repository` to Hive and then updates its in-memory state. This keeps persistence and UI in lock-step, makes repositories trivially unit-testable, and keeps every screen a pure function of state.

**Why boxes are opened in `main()`.** Hive boxes are opened asynchronously once at startup and injected into Riverpod with `overrideWithValue`. The rest of the app reads them synchronously, so no screen has to deal with loading spinners for storage.

---

## Getting started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.27+** (Dart 3.6+)
- A device or emulator (Android, iOS, web, Windows, macOS or Linux)

### Run

```bash
# 1. Install dependencies
flutter pub get

# 2. (First clone only) generate the platform runner folders.
#    This repo ships the cross-platform Dart code (lib/, test/) and config;
#    `flutter create .` scaffolds android/, ios/, web/, etc. without touching
#    existing files.
flutter create .

# 3. (Optional) regenerate Hive TypeAdapters — see note below
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run
```

### Test

```bash
flutter test
```

### A note on Hive adapters (`*.g.dart`)

Hive needs a generated `TypeAdapter` for each persisted type (`Task`, `Priority`, `Habit`). These are produced by `build_runner` from the `@HiveType` / `@HiveField` annotations on the models.

**The generated adapters are already committed** (`task.g.dart`, `priority.g.dart`, `habit.g.dart`) so the project compiles and runs immediately after `flutter pub get` — you do **not** need to run codegen to try it out.

If you change a model (add/rename a field, etc.), regenerate them with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

The output is byte-for-byte equivalent to the committed files.

---

## What I learned / highlights

- **Clean state management with Riverpod.** A single `StateNotifier` owns the canonical list, and *derived* providers (`filteredTasksProvider`, `taskSummaryProvider`, `habitStatsProvider`) recompute filtering, sorting and chart data automatically. UI components stay tiny and declarative.
- **Offline-first persistence done right.** Boxes are opened once at startup and injected via `ProviderScope` overrides, so the data layer is testable in isolation and the UI is free of async storage look-ups.
- **Immutable domain models.** Tasks and habits expose `copyWith`/`toggle` instead of mutating in place, which keeps Riverpod equality predictable and the streak math (`currentStreak`, `bestStreak`) pure and unit-testable.
- **Material 3 theming from a seed color.** The entire palette — light and dark — is generated from one accent color the user picks, and the choice persists across restarts.
- **Thoughtful UX.** Swipe-to-complete/delete, undo snackbars, animated progress ring, friendly empty states, and a back-fillable habit week strip make the app feel finished rather than a demo.
- **Tested where it matters.** Pure streak logic, the Hive-backed repository, and a full-app widget smoke test (boot → empty state → add a task) all run with `flutter test` and no external services.

---

## License

[MIT](LICENSE) © Youssef Awad Sadek

---

## Author

**Youssef Awad Sadek Magoda** — Flutter & Full-Stack Web Developer

- GitHub: [@YoussefAwadSadek](https://github.com/YoussefAwadSadek)
- LinkedIn: [youssef-awad](https://linkedin.com/in/youssef-awad-312b14305)
