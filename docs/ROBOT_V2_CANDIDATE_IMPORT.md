# OneLife Robot Glossy V2 — source-art and review status

**Checkpoint: 2026-11-15.** The 15 Robot entries below are SHA-locked source candidates on `main`, not 15 human-approved production animations. Original source WebPs, rendered PNG atlases, GIF previews, metadata and QA are required before use in Flutter. Robot is not production-ready.

## Already imported to main

| State | Frames | Source SHA-256 |
|---|---:|---|
| idle | 8 | `60b8c04c8430d84355c38413bb871b68975e75e0e891d67bc5de51b6efe707bf` |
| remind | 12 | `f1c9f2dd331125b4e8b3ee8bdd6cd3af2b5a13b9ed41cdd35d807d025b3711ea` |
| alarm | 12 | `57c26cf51c666b552ce2ed2e69c2b54dafd8f2072c9299d7a6f38ac3a88df300` |
| happy | 12 | `e292bc8588f96239a417701009c8fe9e1725148064976f1a7cb71a9f4bb4e87d` |
| overloaded | 12 | `0cb5a9b1e9afd5e2a6a1df69742be04fed4d0c8c0efaee006286775d8a8d58bd` |
| resting | 12 | `9b7861cf59e875f522ab673771141da3c70be821d15469350e08e43950c38109` |
| sleepy | 12 | `e992b5cb0cb1c8a41fd1089f37931f72a4c8ef3cf04a413797162fcc39884b85` |
| recovering | 12 | `c2cd776e890a922f422b91ccd09ee3b98549cbe33b3e589070300fb9dbccceaf` |
| focus | 8 | `7f090931439de0078952277be333feb0c3bf17f85044b6aa3629e04a210da071` |
| study | 12 | `7b194c783c4444e316ce6b0f9825b2f02ae513a54e9648c0799af85ea925ac17` |
| done | 12 | `0f4a6388b88301bfcfe5adaa98d4d30799da1f14256359c18639a783a2b199a4` |
| thinking | 12 | `ed3a1577a6996a02361d0939b6fcfd5047c4daa8e937bae751060f66f5b1626a` |
| sad | 12 | `ec4b5e6b9f363c4e7f93bab0795191027a7300e99233d36e0cfc49b276afd736` |
| balanced | 12 | `4fea809f44da31baa7c9235c1299bdaafe9a6368971722ccdd9ac718d9e08d07` |
| strained | 12 | `ff4419e3edda5f834c3c909f679cf396cc4788a46ba010f4047fb71053ae4229` |

- Source: `assets/characters-v2/robot/<state>/sheet_illustrated.webp`, registered in `assets/characters-v2/animation_sources.json`.
- Renderer: `tools/render_glossy_character_animation.py` produces `sheet.png`, `preview.gif`, `metadata.json`, `qa_report.json` and `manifest.json`.
- Original art source snapshots have true RGBA; catalog/CI verify SHA-256, frame count and visible frame motion. A passing CI is **not** human visual acceptance.
- Reference workflow: [Build glossy character animation assets](https://github.com/aigrouphobinh/onelife/actions/workflows/glossy-character-animations.yml). The `main` render workflow for Robot Done passed: [run 43655281677](https://github.com/aigrouphobinh/onelife/actions/runs/43655281677).
- Source registration commits: [Idle](https://github.com/aigrouphobinh/onelife/commit/d588d6f8161caaa93ff49b62ed6af0a6e4403ce9), [Remind/Happy/Overloaded](https://github.com/aigrouphobinh/onelife/commit/405aafc1315630569d708e7aeefba9fd7974414a), [six additional states](https://github.com/aigrouphobinh/onelife/commit/10315ceb4510ebf43e6ed675c409a935f82dfd0c), [Done](https://github.com/aigrouphobinh/onelife/commit/9f3e57459990430c071e679d7cbe4b82e95c9ded), [Thinking](https://github.com/aigrouphobinh/onelife/commit/2eb6f8b95b92).

## Final Robot sources committed on `main`

- [Sad — original 12-frame WebP](https://github.com/aigrouphobinh/onelife/commit/420635c2b221672c6c4a557d53508a5d8e955e24)
- [Balanced — original 12-frame WebP](https://github.com/aigrouphobinh/onelife/commit/1983d41b82d3decabbbbfb3d248f308ced45d732)
- [Strained — original 12-frame WebP](https://github.com/aigrouphobinh/onelife/commit/ee319cdf08e1e425d13f5f0917dcdee62e2c7aec)

All 15 Robot source keys now exist on `main`; renderer-produced PNG/GIF,
metadata and QA must still be verified against GitHub Actions. A poster or
static master does not count as a motion source. The three new sheets'
SHA, origins and local technical QA are recorded in
[Robot final-three art QA](ROBOT_FINAL3_ART_QA.md).

## Open product gates

- Manual compare on light/dark at 64, 96 and 144 px (silhouette, antenna, face, foot anchor, cutout edge).
- Confirm loop semantics, reduced-motion and screen-reader alternatives.
- Flutter preview/selection tests and battery/performance on real Android and iOS devices.
- `productionReady=false` until all required acceptance gates are signed off.

## Reproduce

```bash
python tools/check_glossy_source_catalog.py
python tools/render_glossy_character_animation.py --character robot
python tools/check_mascot_coverage.py
```

Do not change or duplicate the existing 15-minute GitHub Actions schedule.

## Thinking and Flutter preview checkpoint (2026-11-15)

- Original new source: `robot/thinking/sheet_illustrated.webp`, 12 poses, 4×3 cells, SHA-256 `ed3a1577a6996a02361d0939b6fcfd5047c4daa8e937bae751060f66f5b1626a`, 145 ms one-shot. Verified renderer QA: 12 frames, 11 visible adjacent differences, minimum RMS 31.85.
- Source imagery was cleaned from an AI-generated RGB grid into true RGBA. Human comparison against `robot/master.png` is pending; anti-aliased edges and tiny detachable symbols require visual review on real dark/light screens.
- Flutter now declares the 12 existing Robot PNG atlases and provides `RobotAnimationGalleryPage` with live `GlossySprite`, source-derived timing, replay, accessible descriptions and reduced-motion support. Widget and pixel-alpha tests are committed, but passing Flutter CI has not been independently confirmed.
- **Source coverage:** Cat 15, Dog 15, Robot 15, Sprout 0 = 45/60 source candidates, not product release approval. No original Robot state keys are missing. Do not use previous generated Dog poster images as Robot assets.
