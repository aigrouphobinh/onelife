# OneLife — Dog Study / Glossy Kawaii V2 source and runtime

**State:** `dog/study`. **Status:** original 12-frame source committed on `main` as a reviewed *technical candidate*; art and phone-device approval pending.

## Art direction and frame acting

Use the selected orange/cream chibi puppy identity: glossy round brown eyes, white forehead curl, orange floppy ears, blush, white belly/paws, curling tail, red-brown thick outlines. Book is **pastel purple with cream pages**, without any written text.

| Frame | Action |
|---|---|
| 00 | Neutral alert sitting, without book |
| 01 | Notices a book, looks toward it |
| 02 | Inspects closed book |
| 03 | Puts paws on book |
| 04 | Opens the book |
| 05 | Looks down and begins reading |
| 06 | Turns a page using paw |
| 07 | Small moment of discovery and wonder |
| 08 | Happy smile while looking at the open page |
| 09 | Gently closes book |
| 10 | Releases paws and breathes calmly |
| 11 | Returns to neutral idle-compatible pose |

This expresses a friendly study session, not inferred mental state or device-observed attention. No voice, labels, watermark, opaque background, printed checkerboard, or composite still-image animation.

## Exact source and export

- Commit: `5ed2ac0021dd2d560f50dd7f89bc49aa6e16f4e6`.
- Original source: `assets/characters-v2/dog/study/sheet_illustrated.webp`.
- SHA-256: `22527ed1447616233b9672df9410baed71cde1641f538f7d64208148f7b12e4c`.
- Geometry: 1024×768 pixels; **4 columns × 3 rows**, 12 cells of 256×256 RGBA; transparent background, no painted white/caro.
- Playback: **140 ms/frame**, `loop=false` (once), final frame connects toward Idle.
- Generated: `sheet.png` (true-alpha runtime), `preview.gif` (matte-backed preview), `metadata.json`, `qa_report.json`, `candidate_qa.json`.
- Provenance: original AI-generated visual candidates for OneLife in ChatGPT, cleaned and assembled with Pillow and transparent alpha masking; not an acquired third-party game asset.
- Local technical inspection: about 52.7% fully transparent pixels; no clipped cells or near-duplicate adjacent transitions.
- GitHub QA: 12 distinct frames, 11 changes; minimum adjacent visible RGB RMS 57.98, source checksum matches renderer. This **does not** certify animation acting or production readiness.

## Flutter use

`GlossySpriteSpec.dogStudy` loads the PNG directly using Flutter's image codec, preserves transparency via `Canvas.drawImageRect`, and honors `MediaQuery.disableAnimations`. Home adds **Học tập** alongside **Hồi phục** and **Tập trung** without changing note storage. This is not a usage-statistics claim.

## Open acceptance gates

- [x] Source imported to `main`, SHA-256 verified
- [x] 12-frame alpha/geometry/adjacent frame technical checks passed
- [x] PNG/GIF/metadata generated and registered
- [x] Flutter widget/state selection and associated tests committed
- [ ] Flutter CI result independently confirmed
- [ ] Pixel/animation review on both light/dark at 64px, 96px and 144px
- [ ] Transition to Dog Idle reviewed on device
- [ ] Battery/reduced-motion/large-text device acceptance
- [ ] Human art sign-off; keep `productionReady=false`

**Coverage after importing Dog Study:** Cat 15, Dog 10, Robot 0, Sprout 0 = **25/60 sourced** (not 25 approved).
