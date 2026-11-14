# OneLife — Next actionable Glossy Kawaii mascot task

**Checkpoint 2026-11-15:** sourced animation coverage **26/60** (Cat 15, Dog 11, Robot 0, Sprout 0), **34 sources still missing**. Count source artworks, not human-approved animations. The deterministic asset checker may overwrite this summary on its next scheduled run.

## Next original-art task: dog/thinking

- Use `assets/characters-v2/dog/master.png`, plus committed Dog Idle/Focus/Study/Done as consistent orange-and-cream Glossy Kawaii identity references.
- Draw **12 genuinely distinct poses** in a single 4 × 3 atlas of 256 × 256 RGBA cells (1024 × 768), showing curious thinking: calm glance → eyes look up → tiny head tilt → gentle forepaw to cheek → subtle blink → a modest idea spark → return to neutral Idle.
- Ensure **true transparent alpha**, not painted checkerboard or white matte; no text, speech-bubble labels, watermark, poster borders or cropped ears/paws.
- Suggested `frameDurationMs=145`, `loop=false`. The final frame should visually return to Dog Idle pose.
- Commit verified original WebP to `assets/characters-v2/dog/thinking/sheet_illustrated.webp`. Record its **real bytes SHA-256**, size, timing, provenance and intended motion in catalog and asset register.
- Run `tools/check_sprite_candidate.py`, `tools/render_glossy_character_animation.py` and validate derived PNG/GIF/metadata on `main`.
- Add `GlossySpriteSpec.dogThinking` and a manual preview state to Flutter only after PNG assets exist. Add per-pixel alpha and choice-switching widget tests.
- Review 64/96/144px on light/dark, reduced motion, battery and actual devices before marking `productionReady`; this gate remains **open** for every newly sourced Dog clip.

After Thinking, original Dog sources still needed: **sad, balanced, strained**. Robot and Sprout are completely unconverted to independently illustrated V2 sources.

**Do not infer full app completion from source coverage.** Flutter CI, runtime testing on actual phones and task-event integration are separately pending.
