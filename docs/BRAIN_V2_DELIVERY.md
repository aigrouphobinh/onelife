# OneLife Brain V2 – Real Raster Asset Delivery

## Scope
- True glossy pink Brain style, not flat vector. See design/STYLE_LOCK_V2.md.
- Source WebP master: assets/characters-v2/brain/master_512.webp (512x512 alpha).
- Source WebP animated reminder: assets/characters-v2/brain/remind/sheet_source_1024.webp (1024x768).
- Github Actions: tools/render_glossy_brain_v2.py emits master.png, remind/sheet.png, remind/preview.gif and metadata/manifest.
- Original larger source images remain available in the conversation ZIP, not claimed to be committed as originals.
- 12 distinct reminder poses, 256px cells, 110ms per frame, 4x3 atlas.

## Status and limitations
V2 is a design pilot, not a fully replaced 75-animation library. Brain/remind and Brain master are the first real v2 raster assets; 14 other Brain states and four other character packs still use archived V1 art. Existing V1 files are retained for comparison and rollback.
Automated clipping/alpha/frame tests are separate from manual art review and battery/Flutter testing. Do not claim production-ready or user usage AI implemented.

## Next
1. Visually review Brain/remind at 64, 96, and 144 logical pixels.
2. Produce glossy idle, overloaded and resting as 3 distinct hand-posed clips.
3. Complete remaining states and polish UI dark/light compositions.
4. Integrate with Flutter after art gate.

## Canonical 640px live Brain (reconciliation)
The directly deployed Brain master under assets/characters/brain/master.png is the higher-resolution 640px version and its remind sheet at assets/characters/brain/remind/sheet.png has independently verified 12 real frames. The versioned V2 master/sheet/GIF/metadata mirror these exact Git blobs, avoiding mixed 512/640 standards. The 512px WebP and 1024px source WebP are retained as alternate optimized source references; do not treat them as the current canonical output.
