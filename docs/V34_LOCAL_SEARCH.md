# Local search — 2026-11-16

Home and the Assistant page now open **Tìm ghi chú & công việc**. Search reads
actual saved tasks and notes, including note bodies and completed tasks. It sends
no content to an AI service and needs no account or API key.

- Case-insensitive Vietnamese matching supports unaccented input, Đ/đ, composed
  accents and combining marks. All whitespace-separated words must match the same
  record; punctuation such as `%` and `_` is literal, never a SQL wildcard.
- Filters: all, tasks, notes. Task completion and deadline are visible. Task and
  note IDs are namespaced so matching IDs do not overwrite one another.
- Open/edit, delete with confirmation, task completion/reopening and note-to-task
  creation use existing persistence/reminder flows. Results reload after actions.
- Reads debounce 250 ms. Each query invalidates older reads immediately, including
  during debounce. Retry, pull-to-refresh and application resume read current data.
- The shared note editor keeps unsaved content on write failure and allows retry.
  Notes list reads also reject stale responses; failed deletions show an error.
- Closing search closes its independently owned notes connection, including when
  opening was still in progress. Failed opens are retryable.

Tests cover normalization, literal symbols, body matches, record types/status,
refresh after edits, out-of-order reads, retries, filters, actions and note save
failure/retry. This is Flutter/SQLite behavior, not evidence of physical device QA.

## Remaining core gaps

- Android/iOS device verification for backup file providers and reminder delivery.
- iOS native reminder and outside-app integrations listed in the implementation
  baseline are still absent.
- Focus completion notifications after process termination remain unfinished.
- Conversational AI is not implemented; local search does not pretend to be AI.

Search currently reads local records and filters them in Dart so Vietnamese
matching is consistent. A full-text index and pagination are not implemented;
measure real large collections before choosing an indexing migration.
