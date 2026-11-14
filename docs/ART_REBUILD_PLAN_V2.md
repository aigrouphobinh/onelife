# OneLife – Glossy Visual Rebuild Plan (AI Work Brain)

Read in this order: `design/STYLE_LOCK_V2.md` → `docs/DESIGN_BRAIN.md` → `docs/CHARACTER_ANIMATION_SPEC.md` → `docs/BRAIN_BALANCE_DESIGN.md` → `docs/SCREEN_LAYOUT_CONTRACT.md`.

## Sprint A: One canonical character, no application features

| Task | Input | Deliverable | Acceptance |
| --- | --- | --- | --- |
| ART-V2-01 | User's chosen cute/glossy reference | Brain 1024px transparent master + silhouette, expression and palette board | Side-by-side visual fidelity review |
| ART-V2-02 | Approved Brain master | 15 expressions with consistent eyes, headphones, cheeks, limbs and lighting | Reviewer accepts all states, not only SVG structure |
| ART-V2-03 | Expressions | 4 pilot animation sheets: idle, remind, overloaded, resting; actual intermediate poses | Smooth loops / proper one-shot, no jitter or cut-off props |
| ART-V2-04 | First four clips | Sprite metadata, alpha/edge QA, 64/96/144 preview on dark and light | Test on real preview; no checkerboard background |
| ART-V2-05 | Accepted Brain | Remaining 11 Brain clips, QA, previews | All 15 clips approved |
| ART-V2-06 | Style-locked Brain | Cat, Dog, Robot, Sprout master + 15 states each | Cross-character art direction consistent |
| ART-V2-07 | Approved assets | Rework Home/Onboarding/Habits/Characters & overlay compositions | Exact character art, coherent glossy icon language |
| ART-V2-08 | Everything above | Production Flutter renderer integration after sign-off | Android/iOS and reduced-motion QA |

## Pipeline

Original user reference → isolated high-resolution model sheet → transparent master → per-state acting keyframes → individually generated in-between poses → consistent frame alignment → RGBA sprite atlas → metadata → real GIF/HTML review → QA and user acceptance → Flutter assets.

Avoid stylizing each frame independently without identity consistency. No third-party copyrighted character copies.

## Repository and status instructions

- Work directly on `main` as requested, but preserve original v1 files under existing locations until approved v2 replacements exist.
- New visual files go in `assets/characters-v2/`; documentation is authoritative at `design/STYLE_LOCK_V2.md`.
- Mark V1 technical checks PASS, V1 visual fidelity FAIL against chosen reference, and V2 visual sign-off PENDING.
- CI must prevent claiming "production art ready" based only on 75/75 technically valid V1 animations.
- Pin the original visual reference by an actual, verified PNG/WebP repo file before allowing autonomous regeneration of the entire asset pack. Do not pretend an external chat file is accessible inside GitHub.

## Designer checklist

- [ ] Correct eye style and glossy catchlight
- [ ] Pink cheeks and chubby, friendly silhouette
- [ ] Violet over-ear headphone volume and consistency
- [ ] Rounded hand/feet readable at 64px
- [ ] No flat SVG / generic mascot fallback as approved art
- [ ] 15 different **body actions** and face expressions
- [ ] True transparent source and no checkerboard fringing
- [ ] Animation timing and stable anchor points
- [ ] Dark/light compositing and no loss of contrast
- [ ] Source art rights and metadata registered
- [ ] Explicit final user approval recorded

## Current milestone

**Style direction fixed; redesigned Brain v2 art production and user acceptance are pending.** Flutter feature development remains outside this sprint.

## 2026-11-14 progress
- Brain master raster v2: exported to GitHub and mirrored to active preview path (art direction approved; further edge clean-up may be needed).
- Brain remind v2: 12 distinct action frames, real PNG/GIF/WebP binary assets, metadata; manual motion QA still pending.
- Remaining animation states (including health/wellbeing), other four character variants and UI pages must be redrawn with the new style. **Do not advance feature code yet.**

## Verified Sprint A progress
ART-V2-01: Brain 512px real glossy master on main; 1254px original remains in downloadable V2 ZIP.
ART-V2-03: genuine reminder 12-pose sequence on main; idle, overloaded and resting pilots still pending. Brain V2 visual review and Flutter runtime tests are pending.

## Brain idle progression
- [x] Idle 8-frame glossy animation and metadata replaced at the active Brain path, after Reminder 12-frame V2.
- [ ] 13 remaining Brain states, including wellness visuals, require original glossy asset generation and review.
