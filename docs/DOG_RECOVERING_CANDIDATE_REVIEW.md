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
