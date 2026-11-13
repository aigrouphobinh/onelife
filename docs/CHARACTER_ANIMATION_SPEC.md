# OneLife — Character Animation & Asset Production Specification

## Asset-first production order
1. Draw and approve canonical character turnaround (front, 3/4, side) and color palette.
2. Produce emotion key poses for every character.
3. Create real intermediate frames for each action, not repeated static images or CSS scaling alone.
4. Export transparent PNG sprite sheets and optionally Lottie/Rive for vector micro-motion.
5. Validate every frame's silhouette, anchor point, facial identity and consistent proportions.
6. Build atlas metadata, preview contact sheets and license manifest. **Only then** implement Flutter playback.

## Initial characters (IDs)
brain (default, pink brain with purple headphones), cat (lavender cat), dog (orange friendly dog), robot (blue rounded robot), sprout (green seedling). Optional later: rabbit, dragon, fox, bear. Every character uses the same state keys but unique poses and motion language.

## State contract and motion directions
| State | Motion (must visibly differ) | Loop | Suggested frames |
| --- | --- | --- | --- |
| idle | breathing, blinking, subtle sway | yes | 8 |
| happy | bouncing, cheeks lift, sparkle | short loop | 10 |
| remind | one hand points to bell, head nods | short loop | 12 |
| alarm | startled jump, ringing gesture, bell recoil | short loop | 12 |
| focus | sits still, eyes tracking book/screen, slow breathing | yes | 8 |
| study | opens book, page turn, focused glance | yes | 12 |
| sleepy | eyelids droop, yawn, Z particles | yes | 10 |
| done | thumbs-up/checkmark and celebration hop | once | 12 |
| thinking | eyes look up, question bubble, thoughtful tilt | yes | 8 |
| sad | gentle droop, empathetic expression (no shaming) | once | 8 |

## Technical sprite spec
- Master art: layered vector or layered raster with transparent background, min 1024x1024 per character pose.
- Runtime sprite cell: 256x256 px RGBA PNG; use 512x512 for high-density export if needed.
- Sprite sheet: 4 columns x 2/3 rows as needed; equal cells, no gutters, captions or numbering.
- Frame timing: idle 140ms, happy 85ms, remind 110ms, alarm 80ms, focus 160ms, study 120ms, sleepy 180ms, done 95ms, thinking 140ms, sad 160ms; tune in device tests.
- Baseline/anchor: bottom center (0.5, 0.92); keep full silhouette within frame and avoid jitter.
- Naming: assets/characters/<character_id>/<state>/sheet.png and metadata.json.
- metadata.json: characterId, state, frames, columns, rows, frameWidth, frameHeight, frameDurationMs, loop, anchorX, anchorY, sha256, licenseRef.
- No text/watermarks embedded in sprite assets; particles separate layers for performance.
- Optimize texture atlas and cache; pause when offscreen, low-power mode reduces frame rate; reduced motion shows approved static pose.

## Mascot-specific motion personality
brain: squash/stretch, headphone bounce; cat: tail flick and ear twitch; dog: floppy ears and wagging tail; robot: eye LEDs and mechanical arm; sprout: leaf sways and gentle stem bounce.

## Icons and UI kit prerequisites
SVG icons (Lucide or Material Symbols with license attribution), sizes 20/24/32; custom notification/bell, check, focus, sleep, calendar, privacy, local-AI glyphs; sound cues optional and muted by default; no third-party copyrighted character likeness.

## Asset manifest and QA
For each exported file record: source author/tool, creation date, license, modification rights, SHA-256, dimensions, transparency, state, animation preview. Validate transparent background, no clipped limbs, no frame duplicates, 10 states/character, 5 initial characters = 50 distinct animation clips. Frame counts are target specs, not delivered assets.

## Deliverables / DoD
Approved character sheets + expression boards + all 50 motion clips + manifest + contact sheets + in-app preview design; screenshots at 1x/2x/3x. Do not claim complete until verified.

## Additional opt-in Brain Balance clips (non-medical)
For each character, produce separate transparent sprite sheets: `balanced` (8 frames, 140 ms), `strained` (10 frames, 160 ms), `overloaded` (12 frames, 115 ms), `resting` (10 frames, 205 ms), `recovering` (12 frames, 110 ms). These 25 clips add 260 frames to baseline 50 clips/500 frames, for a 75/760 combined asset inventory. `overloaded` uses abstract comic stress effects, never permanent injury depiction. See `BRAIN_BALANCE_DESIGN.md` and art review.
