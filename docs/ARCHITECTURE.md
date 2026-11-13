# Architecture Decision Record

## ADR-001 Flutter and local-first
Flutter/Dart targets Android first and iOS next. No backend required for MVP. Use SQLite for persistence (migration/versioned schema), device file storage for attachments, OS local notification APIs for reminders. Implement domain repositories to decouple UI from storage.

## Modules
- app: navigation, theme, localization
- capture: notes and import via share sheet (later milestone)
- search: local full-text search (SQLite FTS5; fallback indexed LIKE during foundation)
- tasks: due dates, completion, reminders
- privacy: permissions, export/delete, encryption review
- optional-ai: on-device OCR/classification; disabled unless explicitly enabled

## Data model
notes(id UUID, title, body, created_at UTC, updated_at UTC, deleted_at nullable); tasks(id UUID, note_id nullable, title, due_at UTC nullable, status, created_at UTC, updated_at UTC); attachments(id, note_id, path, mime, size, hash). Add indexes on updated_at and due_at. Persist timestamps in UTC and display in device timezone.

## Reliability
Schema migrations, atomic writes, error boundaries, backups, no credentials in repository. Sync postponed until conflict-resolution and E2EE threat models are approved.
