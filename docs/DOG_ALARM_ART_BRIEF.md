# OneLife – Dog Alarm Glossy V2 (next original art task)

**State:** `dog/alarm` · **Status:** artwork not approved / no production sprite imported. Do NOT count it.

## Character and unique purpose
Reuse the actual `assets/characters-v2/dog/master.webp` as the art reference: golden-apricot glossy fur, **floppy ears**, tiny cream forehead curl, brown eyes with catchlights, round pink cheeks, cream paw tips and belly, small nose, fluffy curled tail. No red collar, calendar, green checkmark, or notification bell—those belong to `dog/remind`, which already exists.

**Visual difference from Remind:** this is a time-specific alarm using one **small twin-bell analog alarm clock with hands**, visually distinct from a single gold notification bell. The puppy briefly startles at the clock, its floppy ears bounce and its paws reach toward the alarm, then it calms down. Keep the scene gentle, non-flashing and non-shaming.

## Twelve independently illustrated poses (4×3 sheet)
1. Puppy sleeping comfortably with eyes closed, clock quiet nearby
2. Clock rings with two small motion arcs, eyes still closed
3. Eyes blink open, tiny surprised mouth
4. Ears lift/bounce slightly, clock rings
5. Head tilts toward the **clock face**
6. Both eyes wide, small yawn
7. Puppy reaches a paw to the clock
8. Paw touches/silences alarm
9. Clock is quiet, puppy stretches
10. Tiny shake of ears and shoulder
11. Smiling alert pose, no ringing marks
12. Returns to neutral look ready for next task

Do not bake a checkerboard, panel lines, captions, numerals, page footer or UI decorations into source. No giant props cropping out. Avoid a copied master with image rotations and duplicate drawings.

## Build and validation
- Produce 12 true RGBA 256×256 cells in `assets/characters-v2/dog/alarm/sheet_illustrated.webp` (1024×768).
- Import to `assets/characters-v2/animation_sources.json` **only after** the real source passes manual sheet inspection; use a SHA-256 of the actual file, `frameDurationMs=110`, `loop=false`, `generationClass=independently-illustrated-pose-sheet`.
- GitHub Actions renderer `tools/render_glossy_character_animation.py` emits PNG, GIF, metadata and QA. Validate alpha, all 12 frames, 11 adjacent visible changes, 64/96/144px.
- Cross-compare every frame with the Dog master, inspect looping/one-shot behavior and check frame pacing. A changed-pixel count alone is not proof of excellent animation.
- Android alarm semantics are a separate system feature and may require notification/scheduling permissions; this asset does not implement an OS alarm.
- Respect quiet hours and reduced-motion. **Device tests and manual art approval remain pending.**

## Design handoff
Previous attempted Dog Alarm images introduced **a calendar, collar and numbered panels** and therefore were deliberately rejected. Do not publish those as `dog/alarm`.
