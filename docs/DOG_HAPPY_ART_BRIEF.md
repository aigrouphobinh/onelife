# OneLife — Dog Happy Glossy V2 · original sprite production contract

**State:** `dog/happy` · **Status:** NO APPROVED SOURCE. Do not count this animation until illustrated art has been imported, rendered and verified on GitHub.

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

- [ ] Source illustration actually depicts HAPPY, not laptop work or stress
- [ ] 12 individually acted poses, identity checked against Dog master
- [ ] No props or words that belong to another state
- [ ] True RGBA/clean matte, 4×3 atlas with margins
- [ ] Runtime PNG/GIF and verified source SHA on `main`
- [ ] GIF one-shot playback and smooth transition to Idle
- [ ] Mobile art/accessibility/performance review explicitly approved

**Current state:** Dog has Idle, Remind, Alarm, Resting, and Overloaded as technical-QA-passed candidates; Happy remains missing.
