# OneLife — Dog last three Glossy Kawaii source animations

Checkpoint: 2026-11-15. The Dog catalog now has **15/15 source slots** after commit `ce06a1ec4215`. This is **not** 15/15 approved animations or a production release.

## Sources committed to main

| State | Artwork | Source WebP SHA-256 | Frames | Delay | Renderer QA |
|---|---|---|---:|---:|---|
| `sad` | Independently AI-illustrated pose sheet | `dfb69500df076d71a15a0d7078c85f9368d9145e33167e429d55e7f62fffe42e` | 12 | 160ms | 11 transitions; min RMS 29.39 |
| `balanced` | Independently AI-illustrated pose sheet | `39d920af19746138e65eb6b2d8e356ad3274bf1053cc8a4a11b0066fd9363734` | 12 | 180ms | 11 transitions; min RMS 23.58 |
| `strained` | **Retargeted illustrated poses** from an earlier Sad candidate, with original sweat-mark overlays; **not** independently illustrated Strained acting | `4c21977047eb194e18ae63dfcff07dbee432e2c65a47b3e75066ec63fc3846ce` | 12 | 155ms | 11 transitions; min RMS 42.07 |

All files are committed under `assets/characters-v2/dog/<state>/`. Each folder contains `sheet_illustrated.webp` (lossless RGBA 1024×768), `sheet.png` (Flutter true-alpha atlas), `preview.gif` (matte-backed visual review), `metadata.json`, `candidate_qa.json` and `qa_report.json`. The original generated PNG drawings were cleaned into 4×3 independent 256×256 cells with **true transparent alpha**, not a painted checkerboard. Every source checksum was verified against exact uploaded Git blobs in GitHub Actions. PNG output is alpha-preserving; GIF previews display on a solid matte.

## Acting and usage contract

- **Sad:** gentle disappointed look, paws lift near face, quiet tear/exhale, re-centers; avoid blaming users
- **Balanced:** even breathing, calm eyes-closed beat, light posture shift and return to idle; not a measured neurobehavioral outcome
- **Strained:** early worry, slightly furrowed face, paw near cheek, small sweat accent and calming exhale; **temporary technical candidate** pending 12 dedicated Strained drawings

Each state is a user-selected preview only. It is **not an inference of brain damage**, medical condition, phone addiction, or mental health status.

## Remaining acceptance gates

- [x] 15/15 Dog source records exist on GitHub `main`
- [x] Last 3 have exact source SHA checks, real alpha, 12 correctly indexed frame tiles
- [x] PNG/GIF/metadata, candidate and renderer QA for last 3
- [x] All 15 states exposed by `GlossySpriteSpec`, bundle assets and scrollable Flutter gallery
- [ ] 12 **independent** Strained illustrated acting poses, replacing the retargeted technical candidate
- [ ] Real-world art direction review of ALL 15 animations at 64/96/144px on dark/light backgrounds
- [ ] Flutter CI analyzer/tests confirmed green, Android/iOS rendering, accessibility, reduced-motion and battery tests
- [ ] Production signoff; `assets/characters-v2/dog/manifest.json` must remain `productionReady=false` until then

**Counts:** Dog 15/15 *source records*, of which 14/15 are classified independent illustrations and 1/15 retargeted. Across Cat + Dog there are 30/60 source records; Robot and Sprout have no original V2 source records yet. These counts are not final art approval percentages.

**Provenance:** Original OneLife AI illustrations generated in this ChatGPT conversation, converted to transparent RGBA with Pillow/OpenCV, then imported with GitHub SHA gates; Strained specifically reuses illustrated poses from a prior generated Sad candidate. Source art is subject to applicable image-generation terms; no outside CC0/MIT attribution is claimed.
