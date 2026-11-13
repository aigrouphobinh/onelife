# OneLife — UI Pages and Region-level Flutter Mapping

## Visual tokens
Primary #7B61FF; secondary #A58BFA; accent #FFC7E0; success #42C98B; warning #FFB547; danger #FF6B76. Light background #F8F7FC; dark background #17152A. Radius: 12/16/24. Spacing: 4/8/12/16/24/32. Font: platform default with Vietnamese glyph coverage. Use contrast checks; tokens are proposals until reviewed.

## Navigation
Bottom nav: Home / Tasks / Schedule / Habits / Assistant. Settings accessible from home avatar; Characters via Settings and onboarding. On narrow phones, assistant entry may be floating action button instead of a sixth tab. Deep links must handle missing permissions.

## Detailed page regions
### HomePage /home
Top SafeArea: greeting + date + profile button (MediaQuery.padding, clock, UserProfile). Mascot hero: MascotStage(characterId, state), action bubble, mute. Today summary: TaskRepository.pendingToday, AlarmRepository.nextUpcoming; quick add buttons. Insight card: HabitRepository.today only if consent. BottomNavigationBar.

### TasksPage /tasks
AppBar + filter chips (today/upcoming/done); TaskList from TaskRepository.watchTasks; TaskTile checkbox; add/edit bottom sheet with title, due date, priority, recurrence. Empty/loading/error states.

### SchedulePage /schedule
Day/week toggle; alarms list and next event; AlarmEditor(TimeOfDay, timezone, repeatDays, snoozeMinutes); OS notification permission rationale and precise scheduling capability warning.

### HabitsPage /habits
ConsentGate first; summary duration, 7-day chart, optional per-app breakdown on supported platforms, threshold editor and pause toggle. Never show fabricated values when permission unavailable. Use UsageStatsManager on Android via platform channel; iOS only supported Screen Time entitlements.

### AssistantPage /assistant
MascotStage + text composer; local rule-based suggestion cards; optional Gemini connection panel with explicit provider disclosure, payload preview and consent. Model selection and reset personal learning controls.

### CharactersPage /characters
Grid with 5 selectable mascots, each previewable across 10 states; animation on/off and reduced motion toggles; save selectedCharacterId locally.

### SettingsPage /settings
Grouped sections: mascot/appearance, notifications/alarms, screen-time consent, AI model and cloud privacy, data export/delete, accessibility, about/license. Show actual OS permission state and open system settings instead of fake toggles.

### OverlayWidget (Android only)
Tiny mascot with drag handle, close button, one-tap reminder. Must not obscure system navigation or intercept unrelated touches. Show opt-in and battery disclosure. On iOS replace with Home Screen widget and notification content.

## Required controllers and device bridge
HomeController, TaskController, ScheduleController, HabitController, AssistantController, CharacterController, SettingsController, OverlayController; repositories TaskRepository, AlarmRepository, HabitRepository, CharacterAssetRepository, PreferencesRepository. Platform bridge UsageAccessService, OverlayPermissionService, AlarmSchedulingService, NotificationPermissionService, AppLifecycleService. Flutter APIs: MediaQuery, WidgetsBindingObserver, ThemeData, TimeOfDay, DateTime, Localizations; plugins chosen only after verifying OS support and maintenance.

## Page acceptance
Every page needs loading/empty/error/permission-denied states, 320–430 logical px mobile layouts, keyboard and screen reader access, text scale 200%, low-motion fallback, dark/light snapshots, privacy audit, and real-device screenshots. No backend dependency for base flow.
