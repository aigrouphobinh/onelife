# OneLife V3.4 — Android task notifications, real implementation

**Status:** Android source committed to `main`; Android APK compilation, notification
delivery and physical-device validation are required before release sign-off.

## What this milestone does

- The user must explicitly enable **Cài đặt → Nhắc việc & Thông báo**.
  Default is **off**. Android 13+ uses the operating system's
  `POST_NOTIFICATIONS` permission dialog.
- Only incomplete tasks with a **future due date** are scheduled in the
  device's private SQLite database. No cloud, sample data or AI-generated
  notifications.
- Uses **inexact** `AlarmManager.setAndAllowWhileIdle`. Android/OEM Doze,
  battery saver and force-stop can delay or suppress delivery. This is
  deliberately **not** an exact alarm and does not request
  `SCHEDULE_EXACT_ALARM`.
- Android notification contains the real task title in the unlocked shade
  and two actual action buttons: **Hoàn thành** and **Nhắc lại 10 phút**.
  A public lock-screen version hides the task title.
- **Hoàn thành** updates `onelife_ui.db.tasks.completed` using
  `WHERE id=? AND completed=0`; the notification is removed only after
  successful persistence, then the Brain home widget is refreshed.
- **Nhắc lại** stores the next trigger in private native preferences, then
  schedules the next inexact alarm. The timestamp survives process restart.
- Opt-in boot receiver restores only *future* reminders after reboot; it is
  disabled again when the feature is turned off.
- Turning reminders off cancels pending alarms and visible reminders but
  **does not delete the task data**.

## Source of truth

- Flutter tasks: `lib/src/onelife_store.dart`
- Flutter permission switch: `lib/src/design_shell.dart`
- Platform channel: `android/app/src/main/kotlin/com/aigrouphobinh/onelife/MainActivity.kt`
- Scheduler: `android/app/src/main/kotlin/com/aigrouphobinh/onelife/TaskReminders.kt`
- Native notification / action buttons: `TaskReminderReceiver.kt`
- Reboot restore: `TaskReminderRestoreReceiver.kt`
- Manifest: `android/app/src/main/AndroidManifest.xml`

## Device acceptance checklist

1. Android 13+: launch OneLife and check the permission has **not** been
   requested before toggling reminders.
2. Enable the switch. Test allow, deny, dismiss and system-level notification
   disabled states. Do not report active until the OS grants access.
3. Create two future tasks with different deadlines; ensure no notification
   fires early. An undated task must never trigger a reminder.
4. Set a task to a time a few minutes from now and observe actual delivery.
   Be prepared for inexact scheduling delays; verify the app says so.
5. Lock the screen; the public notification must not show task titles.
6. Tap **Hoàn thành** without opening Flutter, then reopen OneLife:
   task should be completed in SQLite and widget count updated.
7. Tap **Nhắc lại 10 phút**. It must not mark the task complete or
   duplicate the original notification.
8. Reboot with reminders enabled; future tasks and a pending snooze should
   be restored without opening OneLife.
9. Disable reminders; no future notifications should be scheduled, but all
   saved tasks must stay intact.
10. Test a timezone change, Doze / battery saver, app force-stop, denied
    notification channel, and devices with heavily restricted background work.
11. Open OneLife after completing a notification action; Flutter must reload
    native-modified task status.
12. Validate the actual debug APK from the latest successful `Flutter checks`
    workflow; do not treat analyzer-only success as proof of Android delivery.

## Intentional restrictions

- No exact delivery-time guarantee, no foreground service, no excessive
  wakeups, no external API keys, no notification content on lockscreen.
- Missed due times in the distant past are not backfilled en masse.
- iOS WidgetKit, iOS notifications and Android floating assistant remain
  separate unimplemented work.
- The previously disabled hourly OneLife automation remains disabled.

Official platform references:
- https://developer.android.com/develop/background-work/services/alarms
- https://developer.android.com/develop/ui/views/notifications/notification-permission
- https://developer.android.com/develop/ui/views/notifications/build-notification
