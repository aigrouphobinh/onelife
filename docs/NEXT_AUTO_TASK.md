# OneLife — Next authentic mascot asset task

**Verified GitHub checkpoint 2026-11-15:** **42/60 source records**: Cat 15, Dog 15, Robot 12, Sprout 0. **18 source records still missing**. Source counts are not art acceptance, device approval, or full Flutter completion.

## Next: robot/sad (followed by balanced and strained)

- Keep the exact Robot character identity already sourced in `assets/characters-v2/robot/master.png` and 12 committed Robot sprite sets; do not substitute the orange Dog, a contact sheet, a generic emoji or a 15-state poster.
- Make a distinct 4×3 atlas of **12 original acting poses**: neutral -> ears/antenna pause -> eyes soften -> small slouch -> hesitant hand -> empathetic blink -> gentle exhale -> shoulders relax -> return to Idle. This is a narrative visual metaphor, not a diagnosis.
- **True alpha RGBA** source, 1024×768 WebP, 256px transparent cells, stable body identity, head antenna/feet not clipped, 8px+ edge margin. No painted white/checkerboard background, stray particles, text, labels or watermark.
- File: `assets/characters-v2/robot/sad/sheet_illustrated.webp`. Only count as source after exact file and corresponding SHA-256, catalog entry, generated runtime PNG/GIF/metadata and QA exist on `main`.
- Use `tools/import_glossy_candidate.py` with `--character robot --state sad --frames 12`, review source provenance, run technical `check_sprite_candidate.py` and renderer, verify generated files. Set `productionReady=false` and record manual dark/light + 64/96/144px comparisons and real phone testing pending.
- Then repeat for **robot/balanced** (gentle mindful breathing with actual arms/antenna/eyes poses) and **robot/strained** (soft workload/tension metaphor; no injury or frightening heat). Never fill them from recoloring existing static frames without labeling as retargeted.
- Once original art is committed, extend `GlossySpriteSpec`, Flutter asset bundle and `RobotAnimationGalleryPage` with the actual new states, and test pixel alpha and sprite timing on devices.

**Current UI:** `RobotAnimationGalleryPage` displays the 12 verified Robot sources only; existing Dog 15-state gallery stays intact. **Do not label Robot 15/15 yet.**

## After Robot

Create all 15 independent **Sprout** Glossy Kawaii transparent source sheets; match the committed Sprout master and register the same image/QA/provenance metadata. Then review the retargeted Dog Strained art, Flutter CI and real-device acceptance.

Existing 15-minute GitHub Actions schedules remain unchanged. Automatic QA workers can verify assets but do not generate missing original illustrated poses.
