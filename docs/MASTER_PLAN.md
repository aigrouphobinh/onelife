# OneLife — Master Delivery Plan

## Mission and constraints
Build a real Android-first, iOS-ready personal assistant: capture, retrieve and act on personal information. Offline-first, privacy-first, no required paid API, low-end device support, user control over all destructive actions. No simulated features or claims of completion without tests.

## Core outcomes
1. Save text and links in fewer than three interactions after opening the app.
2. Find saved information offline in seconds.
3. Convert information into tasks and receive timely local reminders.
4. Export/delete personal information and understand every requested permission.

## Phases and deliverables
| Phase | Deliverables | Exit gate |
| --- | --- | --- |
| 0 Discovery | 20–30 interviews, competitor analysis, prioritized pain points | Evidence-backed MVP decision |
| 1 Product | PRD, journeys, acceptance criteria, risk register | Product scope approved |
| 2 Design | Wireframes, accessibility design system, prototype | 8–10 usability tests |
| 3 Architecture | ADRs, data model, security/privacy threat model | Reviewed architecture |
| 4 Foundation | Flutter project, Android/iOS platform files, CI, migrations | Device build and CI pass |
| 5 Capture | Notes CRUD, link import, attachments | Persistence and UX tests |
| 6 Retrieve | Indexed offline search, filters, result navigation | Accuracy and performance tests |
| 7 Act | Tasks, note-to-task, local reminders | Permission and timezone tests |
| 8 Privacy | Export/import, delete, backup policy, security review | Data recovery and security tests |
| 9 AI optional | On-device OCR/classification evaluation | Explicit opt-in, offline benchmarks |
| 10 Beta | Real-device matrix, pilot, accessibility, crash triage | Release readiness evidence |
| 11 Release | Store metadata, signing, policy, staged rollout | Store approvals and monitoring |
| 12 Operations | Crash support, patch policy, release notes, backlog | Ongoing service health |

## Data and trust
Use SQLite for notes/tasks; store UTC timestamps; render local timezone; explicit schema migrations; encrypt sensitive data only after a validated key-management design. Avoid remote AI and invasive permissions. Imported content is untrusted.

## Engineering standards
Feature branches and reviewed PRs; lint and unit/widget/integration tests; dependency/secret scanning; automated Android builds; test on low-end hardware. Do not commit credentials or signing keys.

## MVP acceptance
Offline startup; notes survive restart; reliable literal search; task CRUD and due-date reminders; clear permission denial handling; user-controlled export/deletion; accessibility and localization. MVP is NOT complete until all criteria are proven on real devices.

## Delivery tracking
See [Issues](https://github.com/aigrouphobinh/onelife/issues) for the 22 tracked work items. Status is based on merged code and verified test evidence, not plans alone.

## Current limitations
Repository contains a first vertical slice of offline notes create/search/delete. Tasks, reminders, platform folders, export, import, advanced search, and app-store releases remain unimplemented. Flutter tests have not yet been executed in a configured Flutter SDK environment.
