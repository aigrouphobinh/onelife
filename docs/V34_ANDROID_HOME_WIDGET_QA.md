# OneLife V3.4 — Android home widget: device acceptance

Implementation in `android/app/src/main/kotlin/com/aigrouphobinh/onelife/OneLifeHomeWidgetProvider.kt`.
The widget uses native Android `AppWidgetProvider` and `RemoteViews` (not a
Flutter screen mocked to look like the launcher). It references the actual
bundled `assets/characters-v2/brain/master.png` through Flutter APK assets.

## What the widget actually shows

- Brain master from the existing Glossy Kawaii asset (sampled down to 160px
  maximum to reduce bitmap memory use).
- **Việc hôm nay** aggregate from `onelife_ui.db`: incomplete undated,
  overdue, or due before the next local midnight.
- Focus status from `onelife_focus.db` (idle, running, paused or elapsed).
- Three independent actions: **Công việc**, **Ghi nhanh**, **Tập trung**.
- **Làm mới** manual action. Data is also refreshed after in-app task/Focus
  changes and when the app resumes; the system can periodically ask for a
  redraw (requested every 30 minutes, not guaranteed to exact timing).

No task titles are rendered on the launcher. When the phone reports itself
locked, the number and Focus status are masked. There is no network sync and
no fabricated task or Focus duration.

## Device test (Android 8+ with supported launcher)

1. Install the debug APK from the latest successful **Flutter checks** run
   (download `onelife-v34-debug-apk` artifact).
2. Add one undated task and one due-today task inside OneLife.
3. Open **Cài đặt → Widget màn hình chính → Thêm widget vào màn hình chính**.
4. Confirm the request in the launcher. The native API returns **requested**
   only; the user may still deny the request.
5. If launcher does not support the pin dialog: long-press an empty part of
   the home screen → Widgets → OneLife.
6. Check Brain picture, lavender card, non-placeholder pending count, and
   contrast at 2×2 and wider widget dimensions.
7. Tap **Công việc**, **Ghi nhanh**, **Tập trung**. Each must open the correct
   Flutter destination; no duplicated dialog.
8. Complete a task. The count must decrease. Add a task. The count must rise.
9. Pause/resume Focus; widget status should update from SQLite.
10. Lock the phone and ensure no title/count leaks, then unlock and use
    **Làm mới** to restore the display.
11. Test when no tasks exist, missing SQLite database, database temporarily
    inaccessible, app force-stopped and device rebooted.

### Date/time contract

Both the Today Quick Settings tile and the home widget compare
`substr(due_at_utc,1,19)` against the *next local midnight converted to
UTC seconds*. This intentionally supports both Dart
`yyyy-MM-ddTHH:mm:ss.SSSZ` and `yyyy-MM-ddTHH:mm:ss.SSSSSSZ` strings.
A task due exactly at next midnight belongs to the next day, not today.
See `tools/test_home_widget_sql.py`.

### Native platform constraints

Android launcher owns widget placement, dimensions and any system corner
cropping. Android 8+ supports `requestPinAppWidget` where the installed
launcher allows it; older Android/unsupported launchers use manual placement.
This does not automatically create an iOS WidgetKit extension.

The design intentionally omits a live per-second countdown. The launcher
widget cannot be promised a precise refresh every second and battery
restrictions may delay periodic refresh.

### Release gate

- [ ] `flutter analyze` and all Flutter tests green on `main`
- [ ] `flutter build apk --debug` succeeds with widget receiver/resources
- [ ] Brain source correctly loaded on a physical Android launcher
- [ ] Home widget pins with OS consent on at least two launchers
- [ ] All actions tested from app-closed and app-running states
- [ ] Midnight and lockscreen privacy checked on device
- [ ] No claiming OS-level widget is working on iOS until WidgetKit exists

Official API: https://developer.android.com/reference/android/appwidget/AppWidgetProvider
