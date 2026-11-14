# OneLife — Cat Focus Glossy V2 art & runtime contract

**Status:** WebP source and generated PNG/GIF/metadata verified on `main` after GitHub Actions PASS on 2026-11-14. Manual art and real-device review remain pending.

## Original illustration
`assets/characters-v2/cat/focus/sheet_illustrated.webp` is a 1024×768 RGBA atlas containing 12 source poses, 4 columns × 3 rows. Source SHA-256: `88c7ed1504a1a00e7b7ba0e509aa384df2f171136afff39175932cdd9a5dcde0`.

The Cat keeps the white tuft, glossy lilac body, pink ears and cheeks, dark purple outlines and curled tail seen in the V2 master. Poses progress: get ready → approach small tablet desk → concentrate → write/think → insight → celebrate → calm sustained focus. Props remain pastel-purple; no lettering, watermark or infographic panel in source cells.

## Visual QA notes
- Structural: 12 valid nonempty frames, 11 changing adjacent transitions, no clipped bounding box; processed PNG corners are transparent.
- **Manual concern:** frames 1–3 are at rest with no desk, while subsequent frames include a desk. A repeating loop would cause a noticeable prop jump.
- **Runtime decision:** `loop=false`, show last pose while focus mode stays active. The eventual uninterrupted `focus_loop` asset must be separately authored and approved.
- Review at 64px / 96px / 144px, light and dark backgrounds. The tiny paw-mark on the tablet is decorative and not a required state indicator.
- No phone usage tracking or automatic focus detection is implemented by artwork alone.

## Metadata and integration
- 256px square cells, 4 columns, 3 rows, 12 frames.
- 135ms/frame; `loop=false`; anchor (0.5,0.92).
- Deterministic build: `python tools/render_glossy_character_animation.py --character cat`.
- Generated `sheet.png`, `preview.gif`, `metadata.json` are derived output and checked via GitHub Actions.
- Release gate: human continuity assessment, mobile reduced-motion & TalkBack, CPU/battery profiling, and explicit approval.

**Do not count this as product-ready merely because 9/60 candidate source files are present.**

## GitHub proof
- [Workflow – Build glossy character animation assets](https://github.com/aigrouphobinh/onelife/actions/runs/43577101001) – completed successfully, created real PNG/GIF/metadata.
- [Asset QA and contact sheets](https://github.com/aigrouphobinh/onelife/actions/runs/43577101017) – completed successfully.
- The preview GIF is intentionally one-shot when `loop=false`; the importer now preserves loop semantics for all states.
