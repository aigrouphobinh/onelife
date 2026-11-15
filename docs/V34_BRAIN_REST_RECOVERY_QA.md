# OneLife V3.4 — Resting → Recovering: Native + Flutter QA

**Scope:** Real, user-started Android break timer and original Brain sprite
atlases; no cloud, no background tracking and no medical claims.

## Architecture and actual sources

| Component | File / meaning |
|---|---|
| Session rules | `android/app/src/main/kotlin/com/aigrouphobinh/onelife/BrainBreaks.kt` |
| Android bridge | `MainActivity.kt`: `breakSnapshot`, `startBrainBreak`, `finishBrainBreak`, `cancelBrainBreak` |
| Outside-app Brain | `BrainOverlayService.kt`, genuine WindowManager overlay |
| Screen | `lib/src/brain_break_page.dart` (reached from Brain setup and phone habits) |
| Native assets | `assets/characters-v2/brain/{resting,recovering}/sheet.png` |
| Flutter tests | `test/brain_break_page_test.dart` |
| Build contract | `tools/test_brain_break_contract.py` and `tools/test_brain_native_clip_contract.py` |

## Actual sprite metadata (not invented)

- **Resting:** transparent 1024×768 atlas, 4×3 cells, **10 frames**
  at **205ms each**, `loop=true`. Source is a
  **derived-pose-composite candidate** pending human/device art approval.
- **Recovering:** transparent 1024×768 atlas, 4×3 cells, **12 frames**
  at **125ms each**, `loop=false`. Source is an
  **illustrated candidate** pending continuity/device QA.
- Resting/recovering share the *same single state-cache slot* that previously
  loaded Balanced/Strained/Overloaded. Idle and Focus stay separately cached.
  Missing/bad PNG falls back to Idle rather than displaying fake completion.
- Priority: **Focus** > explicit **Resting/Recovering** > usage-based
  Balanced/Strained/Overloaded > Idle. Starting a break does not stop Focus
  automatically or alter Focus task data.

## Durable session state machine

1. **Idle:** no session. Only a visible user action can start one.
2. **Resting:** user selects **5, 10 or 15 minutes**, saves an absolute
   deadline in Android private SharedPreferences. New sessions store
   both the display wall-clock deadline and the **SystemClock.elapsedRealtime**
   deadline with the boot count. Closing Flutter does not delete it;
   reopening or the visible overlay reconciles it. Flutter shows a
   Stopwatch-anchored native remaining duration instead of trusting a
   user-editable phone clock.
3. **Natural finish:** if due time is observed within **3 seconds** of
   expiry, transition into Recovering for one actual **12 × 125ms**
   animation. If the app is reopened much later, become Idle with no
   artificial late recovery celebration.
4. **Early finish:** the explicit **Kết thúc nghỉ** button transitions
   directly to Recovering for a single cycle.
5. **Cancel:** **Hủy phiên nghỉ** clears the session directly to Idle.
   Cancellation is **not** counted as a successful break.
6. **Recovering:** lasts 1500ms, clamps at frame 11 instead of looping.
   The monotonic recovery TTL is also returned to Flutter, so a manual
   clock edit cannot make it repeat. On the next status reconciliation,
   returns to Idle/personal usage state. A duplicate Finish call during
   Recovering is idempotent and never restarts the clip; another break
   cannot start while recovery is in progress.

- There is **no AlarmManager wakeup, notification, foreground service or
  automatic new overlay** for the break timer. When the app/overlay is not
  visible, no periodic task runs in the background merely to show a mascot.
- An existing opt-in overlay schedules its next state refresh **near the
  saved deadline**, not necessarily every five minutes while resting.
- A foreground Break UI page updates countdown once per second, re-reading
  native state on expiry or resume.
- For new sessions, Android elapsedRealtime includes deep sleep and is
  unaffected by manual clock/timezone edits. BOOT_COUNT (API 24+) detects
  reboot; elapsed-time rollback is a fallback for older devices.
  Reboot invalidates the session rather than fabricating a completion.
  Old V3.4 sessions with no monotonic timestamp use the original wall-clock
  fallback until they expire. This is still NOT an exact background alarm
  and does not keep a process or overlay alive.

## Physical-device checklist (not proven by CI)

1. Cold boot: Brain break UI is Idle; nothing begins automatically.
2. Start 5, 10, 15 minutes; verify the correct Resting loop in Flutter
   and (if separately permitted/started) the actual floating Android Brain.
3. Close app and reopen during a session: remaining countdown derives from
   saved deadline, with no duplicate session.
4. Complete a break early: Recovering plays exactly once and returns to Idle.
5. Cancel a break: goes directly to Idle, no Recovering frames.
6. Keep Brain overlay visible until natural deadline: state flips to
   Recovering, then stays neutral; verify clip plays all 12 frames.
7. Dismiss/force-stop and reopen long after due: no fabricated late
   Recovering animation, but break must no longer show as active.
8. Use Focus concurrently: Focus sprite stays higher-priority; session data
   must not be overwritten.
9. Turn off Usage Access and overlay permission: the in-app break timer
   remains usable. Revoking overlay must remove only the overlay.
10. Verify TalkBack labels and reduced-motion preference; test light/dark,
    64/96/144px, orientation/small-screen menu boundaries and low-end phone.
11. Test screen-off, battery saver, timezone changes, clock correction,
    Android process death and reboot. New monotonic sessions must preserve
    countdown after phone-clock edits; reboot must not replay Recovering.
12. Test repeated Finish taps and expiry-vs-Finish races: Recovering should
    not restart from the beginning.
13. Android JVM regression: run `cd android && ./gradlew :app:testDebugUnitTest`.
    These are actual Kotlin tests of reboot/grace window policy, not proof
    that overlay rendering works on a device.

**Release gate:** Flutter widget tests + analyzer + Android Kotlin compile +
real-art PNG checks + physical device QA. CI green alone is NOT device QA.
`assets/characters-v2/brain/manifest.json` remains
`productionReady=false` until art review is signed off.

Reference: [Android SystemClock.elapsedRealtime](https://developer.android.com/reference/android/os/SystemClock)
counts time spent asleep and is monotonic; [Settings.Global.BOOT_COUNT](https://developer.android.com/reference/android/provider/Settings.Global#BOOT_COUNT)
is available on Android API 24+.
