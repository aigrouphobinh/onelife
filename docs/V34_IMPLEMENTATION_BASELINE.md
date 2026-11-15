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

Open `Tập trung 25 phút` from Flutter Home's shortcut; this is an actual timer,
not a simulated Quick Settings tile.

## Native capability / implementation gate (NOT shipped)

| Design surface | Correct integration | Minimum precondition |
|---|---|---|
| Android Quick Settings | Native `TileService` (Kotlin) linked to shared local Focus state | Generate and build Flutter Android host, declare TileService in manifest, user adds tile |
| Android notification actions | Native notification or maintained Flutter plugin with receiver | Permission and action persistence; no false completed state |
| Home screen widget | Android AppWidget / iOS WidgetKit with shared data bridge | Actual platform hosts and lifecycle testing |
| iOS Control Center | iOS 18+ WidgetKit `ControlWidgetButton` or `ControlWidgetToggle` | iOS host/extension, intent bridge and device test |
| Focus Live Activity | ActivityKit on compatible iOS | Native extension, user consent, lifecycle test |
| Android Brain overlay | `SYSTEM_ALERT_WINDOW` after explicit opt-in | Android host, drag/dismiss controls and low-memory QA |
| Habits/usage statistics | Android UsageStats with opt-in; iOS entitled Screen Time when available | Distinguish missing permission from zero minutes |

The repository originally lacks generated `android/` and `ios/` host projects.
Do **not** claim any native outside-app control exists until its platform project
and app-level tests are present. Scaffold the hosts as a separate tested milestone;
don't insert non-buildable Kotlin/Swift pseudo-implementations.

## Acceptance tests before calling V3.4 complete

- Run `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test`
  and `flutter test` in CI.
- Exercise Focus state persistence, process restart, pause, resume, expiry and
  early stop without a false completion.
- Validate mobile widths 320/375/390/430 dp, Vietnamese long labels, dark/light
  contrast, 200% text, screen reader semantics and reduced motion on physical devices.
- Validate Quick Settings through real Android service lifecycle (off/on/paused,
  locked device, reboot, denied permissions, OEM appearance).
- No invented usage metrics, weather, alarms or background guarantees.
- Sensitive content hidden by default on lock-screen surfaces.
- Keep the prior scheduled OneLife automation disabled until user re-enables it.

## References

- Design review package: `OneLife_Design_V3_4_Outside_App` in the conversation.
- Android Quick Settings tiles: https://developer.android.com/develop/ui/views/quicksettings-tiles
- Android TileService: https://developer.android.com/reference/android/service/quicksettings/TileService
- iOS Controls: https://developer.apple.com/documentation/widgetkit/controlwidget
- ActivityKit: https://developer.apple.com/documentation/activitykit/
