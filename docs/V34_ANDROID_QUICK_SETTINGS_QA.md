# OneLife V3.4 — Android Quick Settings device acceptance

**Status:** Native source committed. A green APK build is necessary but does NOT
prove the tiles behave correctly on a real phone.

## What is real in this milestone

- `FocusTileService` — user-added Focus tile. Tap starts a 25-minute session,
  running → paused, paused → resumed; shares `onelife_focus.db` with Flutter.
- `QuickCaptureTileService` — user-added **Ghi nhanh** tile; opens the real
  Flutter task-entry dialog after unlocking. Task is stored in
  `onelife_ui.db` only after pressing **Lưu**.
- `TodayTasksTileService` — user-added **Việc hôm nay** tile. Reads the actual
  count of unfinished, undated/overdue/due-today tasks from `onelife_ui.db`.
  It does not display titles and hides the count when the phone is locked.
  Tapping it opens the actual Flutter **Việc cần làm** tab after unlocking.
- Flutter **Cài đặt → Điều khiển nhanh Android** — official Add Tile prompt
  via `StatusBarManager.requestAddTileService` on Android 13+.
  Older Android versions need the manual tile editor.
- All three tiles are native and use icons in `android/app/src/main/res/drawable`.
  The OS determines their layout, colors and position.

## Obtain the debug APK

1. Open **GitHub → Actions → Flutter checks**, select the latest successful
   run on `main`.
2. The `build-android` job must show green **Compile Android app and native
   Focus TileService** (this also builds `QuickCaptureTileService` and `TodayTasksTileService`).
3. Download the `onelife-v34-debug-apk` artifact, extract `app-debug.apk`.
4. Install with `adb install -r app-debug.apk`, then open OneLife.
   Debug APK is for QA only; not a release-signed build.

## Scenario matrix (test on Android 13+ and an older Android version)

| Scenario | Action | Expected result |
|---|---|---|
| First installation | Open Settings → Điều khiển nhanh → **Thêm** | Android 13+ shows OS add-tile request; consent controlled by user |
| Denied | Dismiss or decline OS prompt | No claim the tile was added |
| Manual setup | Swipe down twice → Edit → add tile | Tile appears where the system allows |
| Focus start | Tap **Tập trung** tile while idle | Running session persisted, tile active |
| Focus pause/resume | Tap while running, then again | Remaining time frozen while paused; resumes correctly |
| Reopen Flutter | Start Focus by QS, open in-app Focus | Same persisted UTC-based session, not a duplicate |
| Today zero | Clear all pending tasks, open QS | "Không có việc đang chờ"; no mock count |
| Today pending | Add an undated and a due-today task, open QS | Count matches Flutter Today list |
| Today overdue | Leave an incomplete overdue task | Included until completed |
| Today boundary | Due exactly next local midnight | Excluded from today, included in upcoming |
| Today completion | Complete a listed task, reopen QS | Count decreases; never count completed tasks |
| Today cold launch | Force-close app, tap **Việc hôm nay** | Flutter opens real Tasks tab with current SQLite data |
| Today warm launch | Open Focus screen then tap **Việc hôm nay** | Returns to Tasks tab, not hidden beneath Focus |
| Today locked | Open QS while device locked | No title/count shown; unlock required before opening list |
| Cold Quick Capture | Force-close app, tap **Ghi nhanh** | One task-entry dialog opens |
| Warm Quick Capture | Keep app open, tap **Ghi nhanh** | Existing activity receives one action; no duplicate dialog |
| Lock screen | Lock phone, tap **Ghi nhanh** | Unlock prompt before editing; no private data in tile |
| Save | Enter task, tap **Lưu**, revisit tasks | Exactly one item saved locally |
| Cancel | Tap **Hủy** | No task stored |
| Reboot | Reboot phone, reopen QS | Tile remains user-controlled; persisted Focus state resolves |
| Device/OEM variations | Pixel, Samsung, other Android | OS styling may differ; no forced lavender QS panel |

## Useful Android debugging command

```sh
adb shell am force-stop com.aigrouphobinh.onelife
adb shell am start -n com.aigrouphobinh.onelife/.MainActivity \
  --ez com.aigrouphobinh.onelife.extra.QUICK_CAPTURE true
```

For the Today tile bridge, use the equivalent explicit launch intent:

```sh
adb shell am force-stop com.aigrouphobinh.onelife
adb shell am start -n com.aigrouphobinh.onelife/.MainActivity \
  --ez com.aigrouphobinh.onelife.extra.TODAY_TASKS true
```

The command only checks the explicit **cold-start intent bridge**; it does
*not* substitute for tapping the actual tile.

## Non-goals / honest limitations

- No iOS Control Center control implemented in this milestone.
- No background OS alarm or live notification promised for Focus.
- No unrestricted floating Brain on iOS; Android overlay is still a future
  opt-in feature.
- No invented usage statistics, AI assistant answer, or sync status.
- UI regression and device interaction must pass before calling V3.4 complete.

## Documentation

- Android TileService: https://developer.android.com/reference/android/service/quicksettings/TileService
- Android Add Tile: https://developer.android.com/reference/android/app/StatusBarManager#requestAddTileService(android.content.ComponentName,java.lang.CharSequence,android.graphics.drawable.Icon,java.util.concurrent.Executor,java.util.function.Consumer)
- Flutter native channels: https://docs.flutter.dev/platform-integration/platform-channels
