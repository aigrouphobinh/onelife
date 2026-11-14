# OneLife — Next actionable original mascot task

**Checkpoint 2026-11-15:** Cat 15/15 + Dog 15/15 sourced (30/60 overall), Robot 0/15, Sprout 0/15. This document is a **production task list**, not an art approval or app release. Background deterministic tasks may refresh this document.

## Dog character — source batch completed, signoff outstanding

- Dog 15 source paths, SHA locks, PNG/GIF/metadata, alpha and sprite QA are committed on `main` ([art/rights/QA record](DOG_LAST3_ART_QA.md)).
- **Important exception:** Dog `strained` is `retargeted-illustrated-pose-sheet`, not independent Strained keyframe artwork; replace 12 frames in a future art review before final production approval.
- Flutter has a manual 15-state gallery with real PNGs and test definitions, but no real-device approval and no verified Flutter CI PASS.
- The Dog manifest keeps `productionReady=false`; do not automatically promote it because count reached 15.

## Next original illustration work: Robot Idle → full 15-state sequence

- Use the existing Robot master (`assets/characters-v2/robot/master.png`) and [Glossy Kawaii V2 style lock](../design/STYLE_LOCK_V2.md).
- First deliver 8 real frames for Robot Idle, 4-column 256×256 transparent cells, matching appearance; then proceed through Remind, Alarm, Resting, Overloaded, Happy, Sleepy, Recovering, Focus, Study, Done, Thinking, Sad, Balanced and Strained.
- Source must be a genuine 4-column WebP RGBA sprite sheet, no fake white/checkerboard matte or unlabeled poster, with distinct key poses, matching identity and stable ground anchor.
- Use `tools/import_glossy_candidate.py` for SHA-locked source verification, then renderer, PNG/GIF/metadata generation, Flutter registration and tests.
- Every newly generated sheet must be inspected on dark and light backgrounds at 64/96/144px; do not claim device pass from desktop or CI pixel checks.

## Separate acceptance/engineering backlog

- Confirm `flutter analyze` and widget tests on GitHub Actions for the Dog 15-state gallery; fix failures if any.
- Verify real devices, reduced motion, screen reader labels, battery use and transition into Idle.
- Replace retargeted Dog Strained before human art sign-off.
- Continue 15 original Sprout states after Robot.

**Never report 30/60 sources as 50% of finished mobile app or as 30 approved animations.**
