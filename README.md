# OneLife

One place to remember, find, and finish things.

Privacy-first, offline-first personal assistant for Android and iOS.

## MVP
- Capture notes and links
- Search saved content
- Convert notes into tasks
- Schedule local reminders
- Export personal data

## Stack
Flutter + Dart; SQLite for local data. Optional AI and sync are later phases.

## Documentation
See `docs/` for requirements, architecture, delivery roadmap, security and testing.

**Status:** Foundation in progress. No production release yet.

## Design-first phase (2026-11-14)
- [AI implementation contract](docs/DESIGN_BRAIN.md) and [Screen Layout Contract](docs/SCREEN_LAYOUT_CONTRACT.md)
- [10 visual screen concepts](design/screens) and [design README](design/README.md)
- [75 V1 technical animation clips and 5 vector masters](assets/characters) (not all approved visually)
- [12 icons](assets/icons), [Asset QA](docs/ASSET_QA.md), [License register](docs/ASSET_REGISTER.md)
- Design asset delivery **does not** mean the Flutter mobile app is functional or released.

## Glossy V2 — art migration
- [Real Brain V2 master](assets/characters-v2/brain/master.png) and [12-frame reminder sprite](assets/characters-v2/brain/remind/sheet.png) are committed; artwork is still a review candidate.
- [Interactive browser art review](design/review/glossy-v2.html): compare old/new characters, play/pause and scrub frames, check 64/96/144px.
- [15-state motion board](docs/V2_MOTION_BOARD.md) and [migration status](docs/GLOSSY_V2_STATUS.md).
- **Only Brain master + remind are V2.** All other glossy states, character variants and real device tests remain outstanding.
