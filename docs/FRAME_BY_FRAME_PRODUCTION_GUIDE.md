# OneLife – Frame-by-frame Glossy animation production pipeline

**Purpose:** avoid the recurring problem where an image generator produces a poster/infographic with labels rather than a usable 4×3 sprite atlas. This guide does not claim remaining character animations have been generated.

## Source of truth
- Character identity: `assets/characters-v2/<character>/master.png`.
- Art style: `design/STYLE_LOCK_V2.md` (glossy lavender/pink chibi; no flat SVG replacement).
- Expected 15 states: `docs/OTHER_MASCOT_ANIMATION_PLAN.md`.
- Approved source importer: `tools/render_glossy_character_animation.py`.

## Production workflow

1. Design the acting progression before drawing. Example Cat Study (12 poses): notice book → pick up → open → eyes track page → paw turns page → take note → moment of uncertainty → rethink → idea → confident reading → close → settle.
2. Generate or draw **one isolated frame at a time**, using the master as identity reference. Keep proportions, eyes, face tuft, ears, blush, paws and tail consistent. No captions, numbers, watermark, poster borders or fake checkered alpha.
3. Save exactly `frame_00.png` to `frame_11.png` as genuine RGBA square images of the same size, centered and bottom-aligned; leave ≥2px transparent padding.
4. Pack:
   ```bash
   python -m pip install Pillow==11.0.0
   python tools/pack_glossy_frames.py --frames-dir ./work/cat/study \
      --output assets/characters-v2/cat/study/sheet_illustrated.webp --duration-ms 140 --one-shot
   ```
5. Check `pack_qa.json`, all frame bounding boxes and a GIF/contact preview by eye. A passing pack is **not** art approval; it only verifies structure.
6. Add verified `sourceSha256` and state timing to `assets/characters-v2/animation_sources.json`.
7. GitHub Actions runs `tools/render_glossy_character_animation.py`, publishes runtime PNG/GIF and updates coverage. Verify files and Action logs on `main` before claiming a new clip.
8. Manually inspect 64/96/144px light/dark playback, consistency and seamless loop/one-shot behavior. Record device, CPU/battery measurements when available.

## Why separate frames

A composite poster often has text/labels and many tiny characters. Cropping rows from that poster does **not** prove 12 real animation frames, their framing, or quality. The packer fails closed on RGB-only images, opaque corners, mismatched sizes, missing numbered files, near-duplicate adjacent frames, and clipped pixels.

## Next original-art backlog

Cat after Study import: Done, Thinking, Sad, Balanced, Strained (five remaining); Stage status requires renderer and coverage verification. Dog/Robot/Sprout: 15 each. Each must get its **own character-specific artwork**, not a recolored Brain. Never manufacture completion percentages by counting poster cells. Flutter, on-device brain-balance rules and live animation QA are separate implementation gates.
