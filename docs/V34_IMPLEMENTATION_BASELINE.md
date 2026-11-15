# OneLife V3.4 — selected implementation baseline

**Selected design:** the user's OneLife V3.4 board (Outside-the-App First).
**Branch:** `main`.
**Implementation policy:** implement real behavior first; do not represent a picture, sample
metric or native system mockup as an operating feature.

## Product orientation

OneLife's main value is to help the user from the surfaces they already use:
Quick Settings / Control Center, notifications, home widgets, lock screen and (on
Android with consent) a compact floating Brain. Opening Flutter should be needed
for detailed management, not every tiny action.

The supplied board has three regions:

1. **Outside the app:** Android Quick Settings, iOS Control Center, actionable
   notifications, lock-screen reminder, home widget, optional Android overlay.
2. **Inside the app:** Home, Tasks, Schedule, Habits, Statistics, Characters,
   Settings.
3. **First run & assets:** onboarding and permissions, native-compatible icons
   and independent Brain animation states.

The pale purple / ink tokens, lavender glass cards and Brain with violet headphones
are source-of-truth for the visual direction; native Android/iOS chrome is always
system-owned and can look different on each OS/OEM.

## Working slice shipped in Flutter (source, not device-approved)

| Action | Implementation | Caveat |
|---|---|---|
| List and complete tasks | SQLite through `onelife_store.dart` | Task creation saves locally, not as OS alarms |
| Select mascot | Persisted local preference, real committed masters | Non-Brain home uses static master until validated animation |
| Start Focus | `FocusSessionController.start(minutes:25)` | Foreground Flutter screen |
| Pause/resume | Persist remaining seconds and new deadline | Works without native Quick Settings |
| Resume after app background/relaunch | UTC deadline in `onelife_focus.db` | Local clock can change; no OS alarm promise |
| Finish naturally | Persist completed on next load if deadline expired | Does not fire system notification after process termination |
| End early | Returns to idle, not counted as completed | No misleading success report |
| Brain Focus display | Committed alpha sprite `brain/focus/sheet.png` | Art/phone QA still pending |
| Add Quick Settings tiles | Flutter Settings > Điều khiển nhanh Android | Android 13+ official add-tile prompt; older versions require manual edit |
| Quick Capture | Native tile launches the real Flutter task-entry dialog | Cold/warm app paths via `onelife/quick_capture`, local SQLite task, device QA pending |
| Android home widget | Native AppWidgetProvider/RemoteViews with bundled Brain master, SQLite task count, Focus state and three deep links | Added in source, pending APK and launcher QA; no iOS widget yet |
| Today Tasks QS | Native tile reads only aggregate incomplete/due-before-midnight count from `onelife_ui.db` | Lockscreen hides the count; tap opens real Flutter Tasks tab; device QA pending |
| Interactive notifications (Android) | SQLite-backed inexact alarms; complete and 10-minute snooze actions on native notifications | APK CI passed previously; OS delivery and device QA still pending |
| Brain nổi Android | Real draggable 8-frame Brain overlay with Focus/Tasks/Capture/Hide and explicit special access | 29/29 Flutter tests and Android debug APK passed at run 43685260232; physical OEM QA remains |
| Brain phản ứng theo sử dụng máy | UsageInsights + user-set personal goal, real Balanced/Strained/Overloaded atlas candidates with Focus priority | CI completed before break timer milestone; device/visual approval still pending |
| Brain nghỉ chủ động | Native persisted 5/10/15-minute break; Resting 10-frame loop → Recovering 12-frame one-shot; cancellation does not recover | Source and test added; latest APK/physical QA pending |

Open `Tập trung 25 phút` from Flutter Home's shortcut; this is an actual timer,
not a simulated Quick Settings tile.

## Native capability / implementation gate (Android Focus code compiled, device QA pending)

| Design surface | Correct integration | Minimum precondition |
|---|---|---|
| Android Quick Settings Focus | Native `FocusTileService` shares `onelife_focus.db` with Flutter; tap starts, pauses or resumes 25 minutes | Initial APK compile passed; device lifecycle QA outstanding |
| Android Quick Settings Ghi nhanh | Native `QuickCaptureTileService` opens Flutter task input after unlock; `MainActivity` delivers cold/warm launch via MethodChannel | Compile and device interaction confirmation for this new service pending |
| Android Quick Settings Việc hôm nay | `TodayTasksTileService` reads SQLite `tasks` count; 0 means no tasks; hides count when locked; user tap opens Flutter tasks via `MainActivity` | CI compilation and real Android tile QA pending |
| Android notification actions | `TaskReminders`, receiver actions, opt-in runtime permission, reboot rescheduling | 26 Flutter tests + earlier APK CI passed; device delivery, Doze and lockscreen QA pending |
| Home screen widget (Android) | `OneLifeHomeWidgetProvider` reads real local data, masks counts when locked, can request pin from compatible launchers | APK compilation and device/home-launcher QA pending |
| Home screen widget (iOS) | WidgetKit extension, shared App Group data bridge | Not implemented |
| iOS Control Center | iOS 18+ WidgetKit `ControlWidgetButton` or `ControlWidgetToggle` | iOS host/extension, intent bridge and device test |
| Focus Live Activity | ActivityKit on compatible iOS | Native extension, user consent, lifecycle test |
| Android Brain overlay | BrainOverlayService creates TYPE_APPLICATION_OVERLAY, real Idle/Focus atlases and drag/actions | APK built at run 43685260232; Android device/permission/revocation QA pending |
| Habits/usage statistics | Android UsageInsights reads UsageEvents after explicit Usage Access; Flutter PhoneUsagePage displays observed minutes and 90/180-minute nudge tiers | Approximate foreground time, Android device QA pending; iOS Screen Time entitlement not implemented |

Flutter Android and iOS host project folders were generated under `android/` and `ios/`.
Focus, Ghi nhanh and Việc hôm nay tile services are registered in
`AndroidManifest.xml`. Earlier versions with Focus and Ghi nhanh passed
`flutter build apk --debug` in GitHub Actions. The newest Today Tasks tile
and its deep-link bridge require fresh compilation and physical device QA.
Android 13+ uses the system `StatusBarManager.requestAddTileService` prompt.
**This is not device QA**: the user still needs to add the tile and test
on real Android hardware; the iOS control and other outside-app surfaces
remain unimplemented.

## Acceptance tests before calling V3.4 complete

- Run `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test`
  and `flutter test` in CI.
- Exercise Focus state persistence, process restart, pause, resume, expiry and
  early stop without a false completion.
- Validate mobile widths 320/375/390/430 dp, Vietnamese long labels, dark/light
  contrast, 200% text, screen reader semantics and reduced motion on physical devices.
- Validate Quick Settings through real Android service lifecycle (off/on/paused,
  locked device, reboot, denied permissions, OEM appearance).
- Add Quick Settings via Android 13+ official prompt or manually on Android 7–12;
  test refusal, existing tile, repeated taps, screen locked, and warm/cold launches.
- Verify Ghi nhanh saves exactly one local task, not an unconfirmed fake toast.
- No invented usage metrics, weather, alarms or background guarantees.
- Sensitive content hidden by default on lock-screen surfaces.
- Widget uses `requestPinAppWidget` only after the user taps a setup button; OS
  confirmation is necessary and `requested` is not misreported as installed.
- Overlay is optional, not started in onCreate/onResume/boot; permission prompt and service start are two distinct user actions.
- Keep the prior scheduled OneLife automation disabled until user re-enables it.

## References

- Design review package: `OneLife_Design_V3_4_Outside_App` in the conversation.
- Android Quick Settings tiles: https://developer.android.com/develop/ui/views/quicksettings-tiles
- Android TileService: https://developer.android.com/reference/android/service/quicksettings/TileService
- iOS Controls: https://developer.apple.com/documentation/widgetkit/controlwidget
- ActivityKit: https://developer.apple.com/documentation/activitykit/

## Functional continuation — 2026-11-15

The Schedule page now loads actual SQLite tasks independently of the root tab.
It supports Today, Overdue, All and a selected local calendar date; completed
and undated tasks are excluded. Editing, completion, deletion and creation reuse
the existing shell actions (including deletion confirmation and native reminder
reconciliation). The agenda reloads after actions, pull-to-refresh and app resume,
so native notification changes are reflected. Failed reads expose a retry action;
older asynchronous reads cannot overwrite newer results.

Remaining core work, in order:
1. Focus completion notifications and remaining native iOS integrations.
2. Physical Android verification of reminder delivery, reboot and battery restrictions.
3. Android/iOS native file picker device verification for backup and restore.

The schedule is task management, not an exact alarm clock. iOS native reminder
support and conversational AI remain unimplemented. Local notes/tasks backup and
add-only restore are now implemented; see [backup behavior and QA](V34_BACKUP_RESTORE.md).

## Local search — 2026-11-16

Home and Assistant now expose offline search across tasks and note contents, with
Vietnamese accent-insensitive matching and direct edit/complete/delete/create-task
actions. See [search behavior, tests and remaining gaps](V34_LOCAL_SEARCH.md).
