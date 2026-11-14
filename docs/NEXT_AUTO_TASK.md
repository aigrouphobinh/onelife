# OneLife — Next actionable Glossy Kawaii mascot task

**Checkpoint 2026-11-15:** sourced animation coverage **26/60** (Cat 15, Dog 11, Robot 0, Sprout 0), **34 sources still missing**. Count source artworks, not human-approved animations. The deterministic asset checker may overwrite this summary on its next scheduled run.

## Current gate: import created Dog Thinking transparent candidate

- Use `assets/characters-v2/dog/master.png`, plus committed Dog Idle/Focus/Study/Done as consistent orange-and-cream Glossy Kawaii identity references.
- A **12-frame original-art candidate was drawn locally**: calm glance → eyes look up → head tilt → forepaw to cheek → blink → small idea-star → return to neutral Idle. Source is still not in GitHub, so do not count it.
- Ensure **true transparent alpha**, not painted checkerboard or white matte; no text, speech-bubble labels, watermark, poster borders or cropped ears/paws.
- Suggested `frameDurationMs=145`, `loop=false`. The final frame should visually return to Dog Idle pose.
- Import the exact locally generated true-alpha WebP to `assets/characters-v2/dog/thinking/sheet_illustrated.webp` once the binary is available to the checkout. Verified **local SHA-256**: `9dd79993b84c27cf42e1ae13c465b9ec86cc36807be5e41d4d4164f973e167c4`, 603,910 bytes. Do not register it before the file exists on `main`; see `docs/DOG_THINKING_ART_BRIEF.md`.
- Use `tools/import_glossy_candidate.py` to reject modified/opaque/invalid source and register the exact SHA, then generate PNG/GIF/metadata on `main`. Its CLI is shown in `docs/DOG_THINKING_ART_BRIEF.md`. Generic importer has CI regression tests; GitHub Actions results are pending confirmation.
- Add `GlossySpriteSpec.dogThinking` and a manual preview state to Flutter only after PNG assets exist. Add per-pixel alpha and choice-switching widget tests.
- Review 64/96/144px on light/dark, reduced motion, battery and actual devices before marking `productionReady`; this gate remains **open** for every newly sourced Dog clip.

After the uncommitted Thinking candidate is imported, original Dog sources still needed: **sad, balanced, strained**. Robot and Sprout are completely unconverted to independently illustrated V2 sources.

**Do not infer full app completion from source coverage.** Flutter CI, runtime testing on actual phones and task-event integration are separately pending.
