# OneLife Product Requirements (v0.1)

## Problem
Personal notes, links and action items are fragmented across apps. Users need a private, fast way to capture, retrieve and act on information.

## Personas
Students, working adults and small-business owners. Validate with interviews; do not assume age predicts needs.

## MVP journeys
1. Open app and capture a note with title and body.
2. Search notes by keyword offline.
3. Turn a note into a task with due date.
4. View pending tasks, mark complete and receive local reminders (when permitted).
5. Delete or export personal data.

## Acceptance criteria
- App starts offline without sign-in.
- Saved notes persist across restart.
- Search matches title and body, handles Vietnamese Unicode and empty queries.
- Task completion persists and reminders respect permission state.
- All destructive actions require confirmation; no silent data loss.
- Accessible touch targets, readable contrast, screen reader labels.
- No cloud upload or paid AI dependency in MVP.

## Non-goals
Reading other apps' private data; bypassing OS permissions; autonomous payments; unrestricted notification access; automatic background AI.

## Success measures (targets, not observed results)
>=80% unassisted task completion in usability tests; crash-free sessions >=99.5%; measure D7 retention with consent and privacy-preserving analytics.
