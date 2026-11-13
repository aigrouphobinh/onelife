# OneLife — Animation Runtime & Flutter Implementation Contract v1.0

> **Design handoff, not runtime implementation.** Agents must satisfy the human art-review gate in [ART_DIRECTION_REVIEW.md](ART_DIRECTION_REVIEW.md) before adding the Flutter renderer or overlay.

## 1. Authority and actual source files

- `docs/DESIGN_BRAIN.md`: global product/privacy rules.
- `docs/SCREEN_LAYOUT_CONTRACT.md`: per-page UI region, event and device API mapping.
- `assets/characters/{brain,cat,dog,robot,sprout}/master.svg`: master images and fallback artwork.
- `assets/characters/<characterId>/manifest.json`: character state index.
- `assets/characters/<characterId>/<state>/metadata.json`: exact frame geometry, duration and loop.
- `assets/characters/<characterId>/<state>/sheet.png`: **production candidate** 4-column RGBA sprite atlas, each cell 256×256.
- `assets/characters/<characterId>/<state>/preview.gif`: review artifact **only**, not Flutter rendering input.
- `design/review/index.html`: interactive source-PNG review before implementation.
- `design/screens/dark/` and `design/screens/`: dark/light mockups, not real app screenshots.

## 2. Required domain types (Dart)

```dart
enum CharacterId { brain, cat, dog, robot, sprout }
enum MascotState { idle, happy, remind, alarm, focus, study, sleepy, done, thinking, sad }
enum MascotEventType {
  appOpened, taskDue, alarmDue, taskCompleted,
  focusStarted, focusEnded, studyStarted, studyEnded,
  screenTimeThresholdReached, bedtimeStarted, userTappedMascot
}
class SpriteClipManifest {
  final CharacterId characterId;
  final MascotState state;
  final String assetPath;
  final int frames, columns, rows, frameWidth, frameHeight, frameDurationMs;
  final bool loop;
  final double anchorX, anchorY;
}
```

The above is a future interface contract, not existing Dart code. Final classes may be renamed only if all references and acceptance tests are updated.

## 3. Asset loading (no paid service, no network)

1. Read `assets/characters/<characterId>/manifest.json` from Flutter AssetBundle.
2. Resolve `states[state].file` (e.g. `assets/characters/brain/remind/metadata.json`).
3. Load and validate metadata: `frames > 0`, `columns == 4`, dimensions and timing within supported bounds, `runtimeAsset == sheet.png`.
4. Decode `sheet.png` as a `ui.Image` once per loaded state; never decode on each frame.
5. Crop source frame with `Rect.fromLTWH((index % columns) * frameWidth, (index ~/ columns) * frameHeight, frameWidth, frameHeight)`.
6. Render with `CustomPainter.drawImageRect` into an aspect-preserving destination (64/96/144/192 logical px, as appropriate). Align the bottom center to metadata anchors.
7. Use a `Ticker` or `AnimationController` that advances according to `frameDurationMs`, respecting one-shot `loop == false`.
8. Pause on background/invisibility and dispose decoded atlases when not needed. Never run a busy-loop animation.
9. Defer loading to active character + active state; cache at most the current clip and 1–2 likely next clips under a measured memory budget. A 1024×768 RGBA atlas is ~3 MiB decoded even when the PNG file is small.
10. If asset missing/corrupt, render the local master SVG or a reduced-motion static frame and report a recoverable error — never claim playback succeeded.

## 4. Animation orchestration and event priorities

Base priority: `alarm > remind > done > focus > study > sleepy > happy > thinking > idle`.

- `taskDue` → `remind`, one cycle, then return to previously active background mode.
- `alarmDue` → `alarm` while explicitly scheduled alarm is active; follow user mute/snooze.
- `taskCompleted` → `done` exactly one complete animation, then return to prior mode.
- `focusStarted` → `focus` loop until `focusEnded`.
- `studyStarted` → `study` loop; do not override alarms/reminders.
- `bedtimeStarted` → `sleepy` only in app or on an opt-in surface; never force floating overlay.
- `screenTimeThresholdReached` → gentle optional nudge; maximum 2 times/day, 2-hour cooldown, user can disable; no guilt/shame messages.
- `userTappedMascot` → `happy` or `thinking`, unless a higher priority interaction is active.
- `sad` is an empathetic optional expression, not a punitive response to app use.

Queued events must carry stable eventId and TTL; deduplicate alarms/reminders, avoid repeated loops. Quiet hours suppress noncritical prompts. An animation state transition must not change the underlying task/alarm record.

## 5. Visibility and motion preferences

- `AssistantPreferences.characterId` persists locally; switching character preserves task state and uses `idle` until the new clip loads.
- Respect MediaQuery `disableAnimations` / accessibility preferences plus the user's app-level `reducedMotion` flag. On reduced motion show a stable approved still pose, no animated particles.
- Power-save: throttle or pause on app background, overlay hidden, screen off, or low-battery mode; no always-running animation just to track habits.
- All voice, haptics and cue sounds are opt-in; `assets/sounds/*.wav` are muted by default.
- Screen-reader descriptions must include the semantic reminder/task text independent of the mascot's facial expression.

## 6. Platform bridges and privacy

| Feature | Flutter layer | Android source/API | iOS fallback |
|---|---|---|---|
| In-app mascot | `CustomPaint` / AssetBundle | Flutter canvas | Flutter canvas |
| Floating mascot | `OverlayController` + platform channel | `SYSTEM_ALERT_WINDOW` opt-in; overlay/window policy | No unrestricted cross-app overlay |
| Scheduled reminders | `ReminderService` | OS alarm/notification APIs with permission and exact-alarm eligibility check | User Notifications framework |
| Usage time insights | `HabitService` | `UsageStatsManager`, only if Usage Access granted | Screen Time APIs only with entitlement and authorization |
| Gemini | `OptionalAIProvider` | Explicit opt-in remote service | Same; never claim cloud service is on-device |

All personal history and derived habits are stored on the phone by default. Offline rules handle basic prompts. Remote Gemini is optional and must show a data disclosure/payload boundary.

## 7. Pre-code gate and tests

- Design review for **all 50 clips**, with actual 64px, 96px and 144px playback, including contrast on light/dark.
- Every character/state manually assessed for genuine state-specific motion; note per-frame errors by file name/index.
- Check no clipping, popping, unintentional duplicate frames, inaccurate anchor point, or visually ambiguous overlay-size icons.
- Audio optional and muted by default; test quiet hours and no surprise sound.
- Asset QA pipeline must pass (50 clips / 500 frames / 20 light+dark screen designs / 5 WAV cues).
- After design approval, Flutter implementation needs **unit and widget tests** for time advancement, pause/resume, state transitions, permission refusal, disposal and fallback.
- Profile on a low-end Android phone: memory, CPU, battery, start/stop latency and overlay UI. Do not invent measurements or percent complete.

**Implementation should not begin because this document exists; begin when the design gate is explicitly approved and documented.**
