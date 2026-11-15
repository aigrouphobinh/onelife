# OneLife Robot Glossy V2 — final three independent sprite candidates

**Checkpoint: 2026-11-15.** All three original WebP source atlases have now been SHA-locked and committed to `main`. Human art and real-device QA remain pending.

## Original art produced in this session

Three separately illustrated 4×3 pose sheets were generated for the existing
white-and-blue Robot identity (cyan LED eyes, navy display, antenna, cyan core).
Unlike an overview poster, **each sheet includes 12 actual illustrated poses**
depicting a different action. The original 1448×1086 RGBA sources were
normalized to a 1024×768 atlas with 4 columns and 256×256 transparent cells;
poses were not fabricated by scaling one still across frames.

| Robot state | Frames | Frame ms | GIF loop | Source WebP SHA-256 | Local WebP bytes | Min adjacent visible RGB RMS | Minimum alpha margin |
|---|---:|---:|---|---|---:|---:|---:|
| `sad` | 12 | 160 | once | `ec4b5e6b9f363c4e7f93bab0795191027a7300e99233d36e0cfc49b276afd736` | 431,044 | 16.97 | 16px |
| `balanced` | 12 | 180 | infinite | `4fea809f44da31baa7c9235c1299bdaafe9a6368971722ccdd9ac718d9e08d07` | 458,492 | 28.00 | 18px |
| `strained` | 12 | 150 | once | `ff4419e3edda5f834c3c909f679cf396cc4788a46ba010f4047fb71053ae4229` | 507,608 | 47.34 | 17px |

Source files are packaged in **`OneLife_Robot_V2_Final3_ImportReady.zip`**
and larger review previews in **`OneLife_Robot_V2_Final3_Sad_Balanced_Strained.zip`**
in the producing conversation. The ZIP files remain conversation artifacts; the three **source WebPs** are now actually committed to `main`. Original image-generation IDs:

- Sad: `840f1871-c07f-4978-9773-992d6faedfd7`
- Balanced: `5ada4ebe-af61-4e60-b7e5-b13278a7f3f0`
- Strained: `9c3f1a06-0c37-4ce3-a658-f3a1784786d6`

Original AI-generated OneLife art, not third-party licensed stock. Relevant
image-generation platform terms apply; no CC0/MIT ownership claim is made.

## Verification completed on the producing machine

- **3/3 local technical preflight PASS**: source image decodes as RGBA lossless
  WebP, 1024×768; 12 non-empty 256×256 cells per sheet with transparent alpha,
  no visible pixels on outer frame borders, and no clipped silhouettes by
  alpha-bounding-box preflight.
- **36 genuine candidate frames** tested, each adjacent visible frame pair
  above the 2.0 RGB RMS threshold when composited against a light matte.
- **GIF round-trip** verified 12 frames with correct frame timing; non-looping
  states omit the infinite-loop extension.
- `tools/import_robot_v2_pack.py` `validate_pack()` accepted the
  `ImportReady.zip` as a three-state pack without source mutation.
- Light/dark desk previews were exported. Review at 64, 96 and 144 logical
  pixels on an actual phone remains pending.

## Reproduce and inspect the already-registered sources

```bash
python tools/import_robot_v2_pack.py /path/to/OneLife_Robot_V2_Final3_ImportReady.zip
python tools/check_glossy_source_catalog.py
python tools/render_glossy_character_animation.py --character robot
```

The command without `--apply` revalidates the original ZIP. Do **not** run `--apply` on the current `main`: the three source entries are already registered and the importer protects them from overwrites. GitHub Actions generates PNG/GIF/metadata/QA from committed source files.

Confirmed source commits: [Sad](https://github.com/aigrouphobinh/onelife/commit/420635c2b221672c6c4a557d53508a5d8e955e24), [Balanced](https://github.com/aigrouphobinh/onelife/commit/1983d41b82d3decabbbbfb3d248f308ced45d732), [Strained](https://github.com/aigrouphobinh/onelife/commit/ee319cdf08e1e425d13f5f0917dcdee62e2c7aec). The catalog is now **Robot 15/15** and **45/60 total source candidates**; this does not grant production approval.

## Open release gates

- Human approval against `assets/characters-v2/robot/master.png` at
  64/96/144px on light and dark backgrounds.
- Flutter asset resolver and screen-reader/reduced-motion UI checks.
- Actual Android/iOS performance, battery, accessibility and visual review.
- Preserve `productionReady=false` and existing GitHub Actions schedule.

See `docs/NEXT_AUTO_TASK.md`, `docs/ROBOT_V2_CANDIDATE_IMPORT.md`
and issue #33 for backlog and scope.
