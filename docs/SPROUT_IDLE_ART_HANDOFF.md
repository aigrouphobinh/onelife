# Sprout Glossy V2 — Idle illustration candidate handoff

**Date:** 2026-11-15. **Asset status:** candidate generated and technically validated **outside GitHub**. The WebP binary in this handoff is **not yet on `main`**. Do not count it as a sourced/usable clip until imported and GitHub Actions has verified committed bytes.

## Scope and provenance

- Character: `sprout` (last mascot in the V2 roster); state: `idle`.
- Source: original OneLife AI-assisted illustration, not a screenshot, poster, reused dog or V1 transform.
- Original generator reference: `c2d707da-9869-487f-8043-0880e2e4ab58`, 1774×887 RGBA image (true transparent background).
- Adaptation: crop 4×2 independently illustrated cells, LANCZOS resize each cell to 256×256; export one lossless 1024×512 RGBA WebP source. No recolored static-master frames or automated bobbing counted as acting.
- Visual identity: two shiny green leaves, mint/light-cream round body, green glossy eyes, rosy cheeks and small feet. Compare with the immutable committed `sprout/master.webp`; art approval is not inferred from QA.
- Local handoff ZIP: `OneLife_Sprout_Glossy_V2_Idle_Candidate.zip` (distributed with the current assistant conversation, not published by this commit).

## Source contract, verified locally

| Property | Value |
|---|---|
| Destination | `assets/characters-v2/sprout/idle/sheet_illustrated.webp` |
| File size | 403378 bytes |
| **Source SHA-256** | `73eccc27d340094ff9fac855efc63b7b02dcbbb7807962ad062ec48f0a122a22` |
| Format | WebP with RGBA, lossless |
| Frames / grid | 8 independently illustrated poses, 4 columns × 2 rows |
| Cell / atlas | 256×256 / 1024×512 px |
| Duration / playback | 140 ms per frame, loop |
| Anchor | bottom center (0.5, 0.92) |
| Source QA | 8/8 valid: 10px minimum visible margin, 56%+ fully transparent pixels per frame |
| Motion QA | All seven adjacent visible-frame RMS differences above 38; GIF retains 8 frames and correct 140 ms/loop |
| Manual art approval | pending |
| Phone, accessibility, reduced motion | pending |
| Production ready | **false** |

The handoff archive includes original WebP, RGBA PNG atlas, GIF preview, generated metadata, QA JSON, and light/dark review samples. Source PNG/GIF alone is *not* enough to register a candidate; the original source WebP is mandatory.

## Controlled import — only when binary is actually present

```bash
python tools/import_glossy_candidate.py \
  --character sprout --state idle \
  --source /path/to/sheet_illustrated.webp \
  --expected-sha256 73eccc27d340094ff9fac855efc63b7b02dcbbb7807962ad062ec48f0a122a22 \
  --version 2.50.0-illustrated-candidate \
  --frames 8 --frame-duration-ms 140 --loop
python tools/check_glossy_source_catalog.py
python tools/render_glossy_character_animation.py --character sprout
python tools/check_mascot_coverage.py
```

Verify the SHA-locked source, `animation_sources.json`, `sheet.png`, `preview.gif`, `metadata.json`, `qa_report.json`, and `manifest.json` on `main` before increasing Sprout coverage. Compare all frames at 64/96/144px on light/dark and check layout, leaves and baseline. Never overwrite an existing Sprout state without conflict review.

## Next state order

Draw separately illustrated `remind`, `alarm`, `resting`, `overloaded`, then `happy`, `sleepy`, `recovering`, `focus`, `study`, `done`, `thinking`, `sad`, `balanced`, `strained`. Each requires its own source and checksums; no poster or static reference can be counted as an animation.

GitHub Actions' existing 15-minute schedule must remain unchanged. This handoff does **not** alter the catalog, manifests, or coverage.
