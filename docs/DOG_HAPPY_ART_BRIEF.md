# OneLife — Dog Happy Glossy V2 · original sprite production contract

**State:** `dog/happy` · **Status:** Illustrated source imported to `main`; automatic build and independent art/device review still required. Do not mark production-approved solely from a generated file.

## Identity (non-negotiable)

Source of truth: `assets/characters-v2/dog/master.webp` and the exported `dog/idle` preview. The same round glossy apricot-orange puppy must keep its floppy ears, cream crown tuft, cream muzzle/belly/paws, dark sparkling eyes, pink blush, tiny feet, curling tail, lighting and proportions in **all twelve** frames.

**Happy is NOT Focus, Study, Overloaded or Done.** Two attempted image generations produced a dog working at a purple pawprint laptop with books, cups, batteries and stress indicators; these are **rejected for Happy**, not assets to recycle or count. Happy means simple joy without a workstation, bell, clock, phone, captions or unrelated props.

## Twelve distinct acting poses

| Frame | Action |
|---|---|
| 00 | Neutral smiling, forepaws visible, ears relaxed |
| 01 | Eyes brighten; slight smile widening |
| 02 | Head tilts, ears softly rebound |
| 03 | Raises one small forepaw to wave |
| 04 | Both paws lift, anticipates a tiny jump |
| 05 | Upward bounce; tail extends with no body stretch distortion |
| 06 | Midair joyful expression; paws remain anatomically consistent |
| 07 | Soft landing with compressed knees, gentle shadow |
| 08 | Tail wags and head straightens |
| 09 | Eyes close in a cheerful laugh; cheeks lift |
| 10 | One small sparkle or heart near, not across, face |
| 11 | Settles back into the same neutral smile as 00, ready for Idle |

Frames are **separate illustrated drawings**, not rotations/filters/warped duplicates. Identity, feet baseline, eye highlights and edge padding must remain steady. Keep gentle positive acting with no flashing or excessive particles. If the animation is triggered by a task being completed, it should not run indefinitely.

## Technical asset contract

- Draw a clean **4 columns × 3 rows** sheet, exactly **12 true-alpha RGBA 256×256 cells** (1024×768 total), with no panel borders, white/checkerboard baked-in background, titles, frame numbers or watermark.
- Source path: `assets/characters-v2/dog/happy/sheet_illustrated.webp`. Pin the *actual* source SHA-256; do not fabricate one.
- Catalog entry `dog/happy`: `frames=12`, `columns=4`, `frameWidth=256`, `frameHeight=256`, `frameDurationMs=110`, `loop=false`, `generationClass=independently-illustrated-pose-sheet`.
- Render with `tools/render_glossy_character_animation.py`; confirm PNG, GIF, metadata, manifest, source hash and coverage. 11 distinct adjacent visible changes; inspect **frame 11→Idle** transition and human-perceived motion separately.
- Review at **64/96/144px** on light/dark backgrounds. Verify Android low-end FPS/battery, Reduced Motion/animation disable path, and human approval before production.
- Register asset source and applicable generated-art rights in `docs/ASSET_REGISTER.md`; no assumption of CC0.
- Do not mark art approval solely from CI PASS, and do not claim that these images implement phone reminders or AI features.

## Acceptance checklist

- [x] Illustrated source depicts HAPPY; needs human review against master on device
- [x] 12 distinct illustrated poses; visual identity review on device pending
- [x] No props or words from work/reminder/alarm
- [x] Local transparent 4×3 atlas with validated margins; edge cleanup review pending
- [ ] Runtime PNG/GIF and verified source SHA on `main`
- [ ] GIF one-shot playback and smooth transition to Idle
- [ ] Mobile art/accessibility/performance review explicitly approved

**Current state:** Dog has Idle, Remind, Alarm, Resting, and Overloaded as technical-QA-passed candidates; Happy remains missing.

## Imported original illustrated source
- `assets/characters-v2/dog/happy/sheet_illustrated.webp` is a source of 12 independently illustrated happy poses (not a flat SVG, not a poster).
- SHA-256: `da01cc23446339057f8cb9e09025ca4d8ee32cc0283b900c3199fce290e5c50c` (computed from the actual local WebP before upload).
- Runtime renderer: `tools/render_glossy_character_animation.py`; **PNG/GIF and CI status must be checked after workflow execution**.
- Local geometric QA: 12/12 populated tiles, 11/11 changing adjacent frames, 256px cell, transparent corners, 110ms one-shot. Pixel variance is not proof of seamless motion.
- User art approval, 64/96/144px inspection, phone performance and Reduced Motion remain pending.
