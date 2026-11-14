# OneLife — Dog Focus · Glossy Kawaii V2

**Status:** 12-frame original illustrated candidate generated locally; binary source NOT yet committed to GitHub. This document is not proof of production readiness.

## Character lock

Match the user's approved **Glossy Kawaii** orange puppy reference: apricot-orange floppy ears, thick dark outlines, cream forehead curl, cream muzzle/chest/paws, big dark-brown eyes with round white gloss, rosy cheeks, and curled fluffy tail. Maintain body proportions, stable feet anchor and same facing direction unless a specific frame turns the head.

## Acting / timing

The *Focus* state is a gentle attention cue, not a statement about medical or cognitive condition.

| Frame | Distinct illustrated action |
|---|---|
| 00 | Relaxed alert idle, gazing forward |
| 01 | Notices a nearby cue, eye gaze shifts |
| 02 | Brief natural blink |
| 03 | Small focused crouch, ears settle |
| 04 | Sits upright, attentive expression |
| 05 | Extends one forepaw toward task |
| 06 | Lowers both paws together in concentration |
| 07 | Gently brightens eyes, small positive spark |
| 08 | Curious head tilt |
| 09 | Small forepaw gesture, eyes follow |
| 10 | Releases tension with calm exhale |
| 11 | Returns to clear Idle-compatible pose |

The 12 poses must represent genuinely different physical acting; simply zooming or recoloring one still is not accepted. No laptops, large speech bubbles, text, numbers, border/grid, white matte or fake transparency pattern. Keep sparkles subtle and optional; remove noisy detached pixels.

## Source candidate QA — 2026-11-15

- Locally exported `onelife_dog_focus_glossy_transparent.webp` as lossless WebP, true RGBA, 4 columns × 3 rows, 1024×768; 256×256 per frame.
- SHA-256 of local WebP bytes: `bd84075a2c0aede316170d0270bf8172b619ec61b1b4bbdaa258f5bdf813a6fb`.
- ~43.4% fully transparent pixels, transparent top-left corner, all 11 transitions visually distinct by RMS test, no technical warnings from `tools/check_sprite_candidate.py`.
- Animation preview: 135 ms per frame, `loop=false`, one-shot. GIF preview uses a colored matte; transparent source remains WebP/PNG only.
- The alpha cleanup keeps illustrated pixels and removes small isolated specks. This is AI-generated original project candidate, not an externally licensed third-party image.
- **Not on GitHub yet:** no `assets/characters-v2/dog/focus/sheet_illustrated.webp` binary was committed by this task. Do not copy the above SHA-256 into `animation_sources.json` until the exact file bytes are imported to the repository.
- Manual artistic review, transition-to-Idle review, actual Android/iOS rendering, power use and accessibility approval remain pending. `productionReady=false`.

## Import gate

1. Commit the exact candidate WebP bytes to `assets/characters-v2/dog/focus/sheet_illustrated.webp`; verify its SHA-256 independently.
2. Run `python tools/check_sprite_candidate.py assets/characters-v2/dog/focus/sheet_illustrated.webp --frames 12 --columns 4 --cell 256`.
3. Add an entry for `dog/focus` in `assets/characters-v2/animation_sources.json` with SHA-256, 12 frames, 4 columns, 256px cell size, 135ms, and `loop=false`.
4. Run the existing `tools/render_glossy_character_animation.py --character dog`; verify the generated PNG, GIF, metadata and catalog.
5. Use `GlossySpriteSpec` (see `lib/src/glossy_sprite.dart`) to render the imported PNG; respect platform reduced-motion settings.
6. Only mark art approved after visually inspecting light/dark, 64/96/144 px and real-device playback.

**Current sourced migration coverage remains 23/60, not 24/60.**
