# Local notes and tasks backup

Open **Cài đặt → Sao lưu & Khôi phục**. Save a JSON file through the native file
picker, or select one and confirm the preview to import it. Cancellation does not
save or import anything. The file is plaintext and the page makes that clear;
OneLife does not send it to a server. The OS picker can expose providers installed
on the device, so the destination is chosen by the user.

## Data and restore rules

- Format `app=onelife`, integer `version=1`, UTC timestamps, original note/task IDs.
- Includes task titles, deadlines, creation dates, completion state and full notes.
- Does not include character preference, Focus state, usage history, Android
  permissions, notification opt-in, or snooze state.
- Add-only restore: existing IDs win, even when their contents differ. Counts of
  imported and skipped records are shown. Reimporting a file creates no duplicates.
- Entire payload is validated before any writes: type checks, duplicate IDs,
  valid UTC calendar timestamps, nonempty content, maximum 5 MiB / 10,000 records.
- An independent SQLite connection attaches the notes database. Both tables are
  imported in one transaction; SQL errors roll back inserted tasks and notes.
  This is not a claim of cross-database power-loss durability on WAL configurations.
- Successful restore reloads the shell/widget and requests Android reminder sync
  using the existing opt-in. Existing records/snoozes are untouched. Expired tasks
  remain visible as overdue; notification delivery remains inexact.
- If the data commit succeeds but notification sync fails, the UI explicitly says
  the data was saved and reports the sync failure separately.

## Validation and remaining checks

Tests cover Unicode/UTC roundtrip, unsupported formats, invalid dates, duplicate
IDs, bounded input streams, file/confirmation cancellation and sync failure.
SQLite FFI tests run the actual repositories and schemas, verify add-only repeated
restore and inject a notes write failure to verify rollback of task inserts.

Native picker save/import should still be exercised on Android and iOS devices
(including cancellation, revoked provider access and process death while selecting).
Android APK compilation does not establish iOS compilation or device approval.

Next core feature: search tasks and notes together with direct access to results.
