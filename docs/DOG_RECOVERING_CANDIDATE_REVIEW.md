# Dog Recovering — 2026-11-15 review checkpoint

This document records a **candidate**, not a released asset. The intended visual style is the user's **Glossy Kawaii** puppy reference (apricot-orange floppy ears, cream forelock and muzzle, glossy eyes, soft highlights, clear outlines).

## Deterministic candidate QA

New preflight: `python tools/check_sprite_candidate.py path/to/sheet.webp --frames 12 --columns 4 --cell 256 --json report.json`.

A locally exported, cleaned 1024×768 4×3 transparent candidate passed border, geometry and adjacent-frame pixel checks. This by itself **does not add** the source to GitHub, does not count in 22/60 source coverage, and does not imply human/device approval.

## Visual quality issue still blocking promotion

The generated candidate changes facial expressions and head orientation but does **not** clearly perform all 12 required *recovering* actions, especially distinct forepaw stretching and ear rebound. Technical RMS changes are not proof of truthful animation.

Before adding `dog/recovering/sheet_illustrated.webp` to the repository:
1. Rework 12 keyframes against `docs/DOG_RECOVERING_ART_BRIEF.md`, using the selected Glossy Kawaii puppy as the consistent master.
2. Verify genuine limb/head poses, idle-compatible final frame, no cropped outlines or alpha speckles at 64/96/144 px.
3. Import the reviewed **binary** WebP, compute SHA-256 from the committed bytes, and add the matching catalog entry to `assets/characters-v2/animation_sources.json`.
4. Run `tools/check_sprite_candidate.py`, then `tools/render_glossy_character_animation.py --character dog` and inspect the resulting one-shot GIF.
5. Record provenance, human visual review and actual-device approval separately. Do not mark productionReady without those gates.

**Current status: Candidate generated and preflight script committed; source binary not committed; visual review blocked.**

## Reproducible regression checkpoint — 2026-11-15

- Added `tests/test_sprite_candidate.py` (six cases: valid, duplicate, edge clipping, opaque background, wrong dimensions, invalid frame count).
- The corresponding four synthetic fixture categories (valid, duplicate, clipped edge, opaque matte) were executed locally against the preflight implementation; results matched expected pass/fail. The GitHub-hosted unit test suite is **not yet verified by GitHub Actions**.
- Locally prepared candidate binary: `onelife_dog_recovering_clean.webp`, 1024×768, 12 frames, SHA-256 `8fb0754f38b5bfe73da38e4ea725f1b2a3e3b9d7cc00c429d2cbbb4aa1e30cff`. Preflight returned zero warnings. This hash identifies a **local artifact, not a GitHub blob**.
- **Do not register the above hash in production catalog** until exact verified bytes are committed to `assets/characters-v2/dog/recovering/sheet_illustrated.webp`.
- Motion-acting acceptance is still blocked: expression change alone does not implement the required forepaw stretch. Production status remains candidate/pending.

