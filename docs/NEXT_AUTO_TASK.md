# OneLife — Next actionable mascot task

**Checkpoint synchronized from `assets/characters-v2/animation_sources.json` on 2026-11-15.** The scheduled deterministic asset checker may regenerate this file. This is a task list, not evidence of completed artwork.

- Sourced illustration clips: **25/60** (Cat 15, Dog 10, Robot 0, Sprout 0).
- Remaining original sources: **35**.
- Current release gate: human art/real-device approval still pending; no mascot marked `productionReady`.
- Verified recent source: **dog/study** (commit `5ed2ac0`), true RGBA, PNG/GIF rendered. Flutter Home exposes `recovering`, `focus`, and `study`.

## Next original-art task: dog/done

- Use `assets/characters-v2/dog/master.png` and previous Dog animation sheets as character identity references.
- Draw **12 genuinely distinct Glossy Kawaii key poses** for a small completed-task celebration: notices completion → delighted eyes → paws lift → little bounce → settles back to Idle.
- Required artwork: **true transparent RGBA**, 4 × 3 atlas of 256×256 cells, 1024×768, no painted white background, no checkerboard, no labels/watermarks, stable paw anchor.
- Original source destination: `assets/characters-v2/dog/done/sheet_illustrated.webp`. Calculate SHA-256 from the final committed bytes.
- Register in `assets/characters-v2/animation_sources.json`; run `tools/check_sprite_candidate.py` and `tools/render_glossy_character_animation.py`. Verify PNG, GIF, metadata, source provenance, and visual transitions.
- Import on `main`, then register the runtime PNG in `pubspec.yaml` and `GlossySpriteSpec`; add a usable preview and tests in Flutter.
- **Do not count the state until the source is present in the Git repository and catalog.** Technical checks are not art or device acceptance.

Remaining Dog states after Study: **done, thinking, sad, balanced, strained**. Then create original Robot and Sprout illustrated states.
