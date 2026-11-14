# OneLife – Dog Recovering · Glossy Kawaii V2 production contract

**State:** `dog/recovering` · **Status:** NOT YET ILLUSTRATED; does not count toward animation coverage.

## Purpose
A calm, pleasant **waking up / feeling refreshed** cue after a chosen rest interval, visually distinct from:
- `sleepy`: eyelids drooping and yawning toward sleep;
- `resting`: low-energy breathing while on the lilac cushion;
- `happy`: energetic jumping;
- `overloaded`: optional gentle screen-use break nudge.

No medical claims, euphoric flashing or exaggerated animation. Do not imply that an image diagnoses or treats a condition.

## Master identity
Use `assets/characters-v2/dog/master.webp`, `dog/idle` and `dog/sleepy` as visual references. Keep apricot-gold fur, orange floppy ears, little cream forehead curl, cream muzzle/belly/paws, warm brown eyes with large highlights, rosy cheeks and curved fluffy tail. Stable 256px character box, feet anchor and left-right orientation.

## Frame-by-frame storyboard (12 individual poses)
| Frame | Unique physical action |
|---|---|
| 00 | Peacefully sleepy, eyes gently closed, seated |
| 01 | Small inhale; ears soften |
| 02 | Eyelids open halfway; head rises slightly |
| 03 | Soft blink, tiny smile |
| 04 | Lifts one forepaw for a gentle stretch |
| 05 | Forepaws stretch forward without morphing body |
| 06 | Ears rise/rebound a little |
| 07 | Upright neutral posture returns |
| 08 | Slow head turn toward viewer |
| 09 | Brief cheerful but subtle eye sparkle |
| 10 | Tail makes a small movement; no full celebration |
| 11 | Settles into calm **Idle-compatible** standing/sitting pose |

Avoid alarm clocks, golden bells, phones, laptops, large props, poster titles, numbering, panel borders, text, checkerboard printed on background or cropped ears/tail. Each keyframe must be individually acted rather than a transformed still.

## Asset export and QA
- Source `assets/characters-v2/dog/recovering/sheet_illustrated.webp` — **12 real transparent 256×256 RGBA cells** arranged 4×3 (1024×768).
- Suggested `frameDurationMs=130`, `loop=false`; frame 11 should visually connect to Dog Idle frame 0.
- Run `tools/pack_glossy_frames.py` when frames are supplied individually; register actual SHA-256 in `assets/characters-v2/animation_sources.json`.
- Run `tools/render_glossy_character_animation.py`; check PNG/GIF/metadata/source hashes and QA on `main`.
- Inspect at 64/96/144px in light and dark modes, motion pacing, alpha edges, feet/tail shape, 11 adjacent visible differences and terminal seam against Idle. The raw visible-difference threshold is necessary but not sufficient for art acceptance.
- Respect motion-reduction settings, quiet hours and user opt-in usage metrics. No phone data collection is implemented by the sprite itself.
- Provenance: record original AI generated art and modifications in `docs/ASSET_REGISTER.md`.

## Acceptance gates
- [ ] 12 master-consistent Recovering illustrations created
- [ ] Transparent source imported to `main`, actual SHA-256 registered
- [ ] GitHub workflow successfully generated PNG/GIF and coverage
- [ ] Smooth final frame → Idle reviewed by human
- [ ] Mobile art, accessibility and low-end Android battery checks performed
- [ ] Approved for app use

**Do not mark complete from this planning document alone.**
