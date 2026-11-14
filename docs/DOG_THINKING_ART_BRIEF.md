# OneLife — Dog Thinking / Glossy Kawaii V2

**Checkpoint:** 2026-11-15. This is an **original transparent illustration candidate produced locally**, NOT a committed animation source. The app continues to count **26/60** sourced animations on `main` until its exact WebP bytes are imported and registered. Manual/device acceptance is pending.

## Identity and acting

Use the user-selected apricot-and-cream puppy (orange floppy ears, cream forelock/muzzle/paws, glossy dark-brown eyes, rosy cheeks, thick red-brown contour, curled tail). No text, watermarks, printed checkerboard, props larger than the pup, or fake opaque backgrounds.

| Frame | Physical action |
|---|---|
| 00 | Calm sitting, alert neutral face |
| 01 | Eyes lift and notice a question |
| 02 | Gentle head tilt, eyes consider the idea |
| 03 | Forepaw raised slightly, curious surprise |
| 04 | Paw touches cheek, looks upward |
| 05 | Brief contemplative blink and lowered head |
| 06 | Turns toward viewer with new curiosity |
| 07 | Paw remains near chin, brows draw in |
| 08 | Small idea-star accent, eyes brighten |
| 09 | Soft delighted smile and raised-paw cue |
| 10 | Slow exhale, eyelids close peacefully |
| 11 | Returns to Idle-compatible seated neutral pose |

Visual action is a friendly narrative, **not a claim that phone activity measures or diagnoses cognitive state**.

## Produced local source — technical QA

- Exported `onelife_dog_thinking_glossy_transparent.webp` (lossless WebP RGBA), with corresponding PNG and GIF preview.
- Original AI-generated art, prepared with transparent-alpha masking to remove the image-generation model's **painted checkerboard**. This is not a purchased or borrowed third-party mascot.
- Atlas dimensions: 1024 × 768; 4 columns × 3 rows, 12 independent 256 × 256 frames.
- SHA-256 of **local WebP**: `9dd79993b84c27cf42e1ae13c465b9ec86cc36807be5e41d4d4164f973e167c4`.
- Size: 603,910 bytes. Fully transparent pixels: about 52.82%; no source alpha painted as white background.
- Local `check_sprite_candidate.inspect()`: 0 warnings, all 11 adjacent visible frame changes, minimum RGB RMS 51.45. GIF contains 12 frames at 145 ms each, no infinite-loop extension.
- Inspected example frames 00, 04, 08 and 11 on light/dark backgrounds at 64, 96 and 144 pixels; **this is a desktop image review, not phone acceptance**.
- Rights: original AI-generated project candidate subject to relevant platform service terms; no CC0/MIT copyright license claim.

## Import and verification

Generic importer available at `tools/import_glossy_candidate.py`, with checks for source SHA, image geometry, actual transparency, clipped/near-duplicate frames and conflicting catalog entries. The importer only renders existing artist-created files; it **cannot generate missing artwork**.

Once the exact source is available to the repository checkout:

```bash
python tools/import_glossy_candidate.py \
  --character dog --state thinking \
  --source /path/to/onelife_dog_thinking_glossy_transparent.webp \
  --expected-sha256 9dd79993b84c27cf42e1ae13c465b9ec86cc36807be5e41d4d4164f973e167c4 \
  --version 2.30.0-illustrated-candidate \
  --frames 12 --frame-duration-ms 145
```

Expected after commit: `assets/characters-v2/dog/thinking/sheet_illustrated.webp`, `sheet.png`, `preview.gif`, `metadata.json`, `qa_report.json`, `candidate_qa.json`, source entry and Dog manifest entry.

**Do not update `animation_sources.json`, `pubspec.yaml` or `GlossySpriteSpec` to include this candidate before its binary WebP/derived PNG are actually on `main`.** Preserve `productionReady=false`.

## Open gates

- [x] 12 distinct illustrated candidate frames, PNG and true-alpha WebP generated locally
- [x] Local geometry/alpha/motion/duration technical QA
- [x] Desktop light/dark review at 64/96/144px
- [ ] Exact image source committed to `main`, verified SHA-256
- [ ] Source registered in catalog with derived PNG/GIF/metadata committed
- [ ] Flutter real-asset preview/choice and automated tests committed
- [ ] GitHub CI analyzer and widget tests confirmed
- [ ] Human art/motion acceptance; actual Android/iOS battery, accessibility, performance
