# OneLife — Dog Idle (Glossy Kawaii V2) · production art contract

**Status:** SOURCE ART MISSING. This is a task specification, **not** a finished animation or an approval.

## Canonical identity

Source of truth: `assets/characters-v2/dog/master.webp` (original 512×512 transparent artwork; SHA-256 `43d5f2f2e6026bd0af2255677a04f90bb1b41b88b3704d7c58439bd0af94b045`). It has **warm apricot/golden fur**, large floppy orange ears, tiny curled crown tuft, dark brown sparkling eyes with catchlights, blush cheeks, cream belly/paws, small smiling mouth and curling tail. This dog must look like that master in EVERY frame. Do not use Cat's purple master or "restyle" Cat into Dog.

## Original 8-pose idle cycle

| Index | Acting | Invariants |
|---|---|---|
| 00 | Friendly neutral standing/sitting with paws visible | Exact master silhouette, no extra props |
| 01 | Tiny inhale and ear relaxation | Same face position; tail slightly lifted |
| 02 | Slow blink halfway closed | Catchlights still match when visible |
| 03 | Eyes briefly closed and a warm smile | Both floppy ears remain soft |
| 04 | Eyes reopen, glance a little sideways | Do not change nose or muzzle shape |
| 05 | Tail visibly wags to the left | Small motion arc, not body rotation |
| 06 | Tail swings back right; ears subtly rebound | Feet fixed to ground anchor |
| 07 | Ease back to frame 00 (loop seam) | Same overall pose and proportions |

**Render:** eight *independently illustrated* poses (NOT whole-image rotations or scaled duplicates). Single sheet RGBA 1024×512, 4 columns × 2 rows, 256×256 cell, 150 ms/frame, seamless loop, bottom-center anchor `(0.5,0.92)`. No title, number, checkered transparency baked into background, watermarks, text, floor graphics or panel borders.

## Asset contract and tests

- Create and inspect 8 separate master-consistent paintings or 4×2 clean sheet at 1024×512. Use `tools/pack_glossy_frames.py` to assemble independently painted frames.
- Import `assets/characters-v2/dog/idle/sheet_illustrated.webp`; compute its real SHA-256. NEVER invent a checksum. Add one `dog/idle` source entry to `assets/characters-v2/animation_sources.json` with 8 frames, 4 columns, 256 cells, 150 ms, `loop=true`, `generationClass=independently-illustrated-pose-sheet`.
- CI `.github/workflows/glossy-character-animations.yml` should generate `sheet.png`, `preview.gif`, `metadata.json`, update manifest and coverage. Verify alpha margins >2 px, all 8 nonempty frames, 7 changed neighbor pairs, readable at 64/96/144 px.
- Compare every source frame to the **actual dog master** for eye/muzzle/ear shape consistency. Automated pixel difference is not sufficient to call a clip smooth or beautiful. The loop 7→0 and mobile reduced-motion behavior require real inspection.
- Do not add to the 60-clip completed count until files are readable in GitHub and workflow checks pass. No device-art approval until the user reviews rendered sprite and low-end phone playback.
- Asset provenance: first-party generated illustration from user-approved OneLife style, record generation source, modifications and usage terms in `docs/ASSET_REGISTER.md`. No third-party assets.

## Current next objective

The user's requested pipeline is **art first**, then real Flutter runtime. Cat now has 15 original source-candidate clips; Dog has only the static master and **0 illustrated action clips**. Build Dog Idle first, then Dog Remind/Alarm/Resting/Overloaded, before moving through its other ten states.
