# OneLife — Wukong Glossy Kawaii V2 (extra mascot candidate)

This is an **optional fifth mascot** inspired by the public-domain legendary Monkey King / Tôn Ngộ Không. It is **not** counted in the locked Cat/Dog/Robot/Sprout `60/60` source coverage and is **not** production-approved.

## Visual identity

- Small brown mischievous monkey with pronounced eyebrows, big amber eyes, red scarf and armor, golden cloud headband, red-and-gold Ruyi Jingu Bang staff and curled tail.
- Original OpenAI-generated illustrations, with **no third-party game art or licensed commercial character copied**.
- Glossy Kawaii 2.5D look, strong highlights, recognizable small silhouette, transparent background, consistent costume/staff across poses.

## File layout

```text
assets/characters-v2/wukong/
  master.png           # original hero reference, RGBA 512×512
  manifest.json        # extra candidate, productionReady=false
  idle/
    sheet_illustrated.webp  # independently illustrated 8 poses, lossless RGBA, 4×2 × 256px
    sheet.png               # runtime atlas, RGBA 1024×512
    preview.gif             # 8 frames × 150ms, looping preview
    metadata.json           # runtime playback and SHA-256
    qa_report.json          # technical QA, human/device review pending
    provenance.json         # artwork origins, processing and usage rights
```

`python tools/check_wukong_candidate.py` independently checks alpha margins, visible motion between frames, GIF timing, metadata, and SHA-256. Existing Asset QA on `main` also executes this check; it does not change CI schedules.

## Proposed remaining acting states (not yet drawn)

`remind`, `alarm`, `happy`, `overloaded`, `resting`, `sleepy`, `recovering`, `focus`, `study`, `done`, `thinking`, `sad`, `balanced`, `strained`.

One distinct illustrated pose sheet per state. Do not derive animation from a master poster using simple transforms and do not increment any coverage counter until full source, runtime and review evidence is present.

## Release gates

1. Review at **64/96/144 px** on light and dark Flutter surfaces; inspect monkey face, staff and cape edges and readability.
2. Character selection and asset routing require an explicit approved Wukong integration; the existing Flutter 4-mascot catalog must remain untouched.
3. Test on low-end Android; keep reduced-motion and static fallback where needed.
4. Record design/device sign-off before enabling `productionReady`.

**Current status:** master and `idle` art candidate only, 8 original poses; not user-approved, not connected to Flutter and not part of the 60/60 core requirement.
