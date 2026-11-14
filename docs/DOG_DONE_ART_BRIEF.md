# OneLife — Dog Done / Glossy Kawaii V2

**State:** `dog/done`. **Status:** original 12-pose source on `main`; technical QA passed, human/device art approval pending. Do not set `productionReady=true`.

## Character and acting contract

Keep the approved orange-and-cream chibi puppy identity: glossy brown eyes, white curly forelock, apricot floppy ears, pink cheeks, thick dark outlines, cream muzzle/chest/paws and curled tail. Celebrate finishing a *user-chosen task* without implying a clinically observed state.

| Frame | Physical action |
|---|---|
| 00 | Calm original sitting pose |
| 01 | Notices completion, looks upward |
| 02 | Bright grin; prepares to lift paws |
| 03 | Forepaws rise, body leans forward |
| 04 | Wide delighted smile and double-paw celebration |
| 05 | Starts a small jump, feet lift |
| 06 | Highest jump, both paw pads visible, ears bounce |
| 07 | Gently lands and steadies |
| 08 | One celebratory paw-wave |
| 09 | Playful wink as paws return |
| 10 | Eyes relax, tail makes a small final motion |
| 11 | Back to calm, Idle-compatible sitting |

No text, badges, logos, recorded audio, poster panels or false alpha/checkerboard. Small detached sparkle and bounce accents are intentionally decorative.

## Verified GitHub source

- Original AI illustration produced for this OneLife conversation on 2026-11-15; no external asset downloaded.
- The generated visual contained an opaque printed checkerboard. The working file was **segmented to true RGBA** with a local mask/morphology process, component filtering and transparent pixel export. The checkerboard is **not** present as the PNG/WebP background. Edge inspection on actual mobile hardware is still required.
- Source: `assets/characters-v2/dog/done/sheet_illustrated.webp`.
- Source SHA-256: `f5a8460b467c6fa9e16ea0668f1c8a2135ca578aa9aa7396f82d4cb8cab84767`.
- Geometry: 1024 × 768, 4 × 3 cells of 256 × 256 RGBA, lossless WebP.
- Alpha: about **47.8%** completely transparent pixels across the sheet, verified by local Pillow inspection.
- Playback: `frameDurationMs=125`, `loop=false`, final pose remains still.
- Verified GitHub outputs: `sheet.png`, `preview.gif`, `metadata.json`, `candidate_qa.json`, `qa_report.json`, plus catalog and Dog manifest. GitHub Actions importer commit: `865317c51d46`.
- The importer preflight reported **zero warnings**, 12 visible frames and 11 visually distinct adjacent frame differences (minimum RGB RMS **43.57**). These are geometry/alpha/frame QA results, **not** professional visual animation approval.
- Source rights: original project AI-generated candidate, subject to applicable provider terms; no CC0/MIT license is claimed.

## Flutter integration

- `GlossySpriteSpec.dogDone` loads the actual transparent `sheet.png`, not the matte-backed GIF.
- Home now has a fourth selectable preview state, **Hoàn thành**. This selector is **a manual animation preview**; it is not yet hooked to a persisted Task completion event or true OS usage telemetry.
- Existing offline notes flow is preserved. Test coverage includes asset alpha, runtime mapping and selector transitions.
- Respect `MediaQuery.disableAnimations`. Pending: Flutter CI confirmation, 64/96/144 px art consistency, loop-to-Idle transition, accessibility, frame smoothness, device battery and contrast.

## Remaining gates

- [x] Source WebP committed to `main` with verified SHA
- [x] True alpha + frame geometry and adjacent technical checks
- [x] PNG/GIF/metadata and catalog generated
- [x] Flutter selector and tests committed
- [ ] Flutter analyzer/test run confirmed green
- [ ] Human art review (dark/light, edges and 64/96/144 px)
- [ ] Android/iOS performance, reduced-motion and battery checks
- [ ] Final approval; `productionReady` remains **false**

After this import, original source coverage = **26/60** (Cat 15, Dog 11, Robot 0, Sprout 0). Next missing Dog state: **thinking**.
