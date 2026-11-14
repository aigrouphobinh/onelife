# OneLife V2 – 10-page interactive mobile design prototype

**Preview:** open \`design/prototype-v2/index.html\` from a complete repository checkout. All images reference the **actual** committed 15-state Brain Glossy V2 atlases.

## Pages (10)
Splash, Onboarding, Home, Tasks, Schedule, Habits/Brain Balance, Assistant, Characters, Settings, and Android Overlay preview.

## Interactions
- Navigate between pages (desktop sidebar and mobile bottom navigation).
- Dark/light theme; accessible reduced-motion toggle.
- Real state-dependent mascot PNG playback, cropped by frame from 15 separate atlases.
- Add/complete a **sample** task; animate task completion.
- Change **sample** screen-time minutes and break goal; preview balanced/strained/overloaded/resting/recovering reactions.
- Preview alert, reminder, thoughtful and focus states.
- Character selector now **previews four real original Glossy master artworks** (Cat, Dog, Robot, Sprout), with explicit disabled/unavailable labels. Brain has **15 animation candidates**; Cat has **6 separately illustrated candidate clips (68 frames)** viewable in a dedicated reviewer. Dog/Robot/Sprout only have their glossy masters. No character has passed mobile art/device acceptance.

## Technical honesty
This is **not Flutter** and does not schedule alarms, monitor device usage, interact with overlays, call Gemini, or persist tasks. Sample values are labeled. Native Android/iOS permissions are not requested. No external CDN or paid API. Production integrations must follow \`docs/DESIGN_BRAIN.md\` and \`docs/BRAIN_BALANCE_DESIGN.md\`.

## QA and evidence
The \`v2-prototype-preview.yml\` workflow checks JS syntax, opens all 10 pages with a browser and captures 10 mobile + 4 desktop screenshots in \`screenshots/\`. Design approval, manual contrast review and physical device testing are still required.


## Cat animation proof (2026-11-14)
The Characters card links to `design/review/glossy-cat-idle.html`, which plays 6 original illustrated Cat states (Idle 8 frames; Remind/Alarm/Resting/Overloaded/Happy 12 frames each = 68 total) from committed PNG atlases. This is a QA preview, not a fully selectable, production-approved mascot. Cat has 9 missing states and Dog/Robot/Sprout have 45.
