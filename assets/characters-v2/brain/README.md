# Brain V2 · Glossy Kawaii

The V2 image assets **replaced the live Brain master preview and the remind sprite** on the legacy path while this versioned directory preserves the originals. The v1 SVG sources remain for rollback and for the other 14 not-yet-replaced states.

- `master.png`: 640px RGBA high-detail image (SHA256 9e03b543c2aea0c88d9a824100ee1b5cfd71f8fd1fbb9a9f5fc798af2cd6356d).
- `remind/sheet.png`: 1024×768 RGBA atlas, 4×3 cells at 256px; 12 different action frames (SHA256 c4ff3f6f0689bee11e39df7f85220f76868b987efbb7f65e4d90beff1e51aa3a).
- `remind/sheet.webp`: lightweight design preview; not the runtime atlas.
- `remind/preview.gif`: sequential preview, light surface only.
- `remind/metadata.json`: crop geometry, timing, identity and provenance.

Artwork is sourced from the newly generated OneLife glossy assets in this conversation, visually aligned to the user-selected cute style. The image generation may cause minor pose identity drift; finish manual frame-by-frame review before calling it production final.

Do not export the old flat `brain/remind/sheet.svg` over the V2 PNG; `tools/generate_character_assets.py` has a protected V2 override for this state.

**Current:** Brain master + remind V2 only. 14 other Brain states and all four non-Brain mascots still use V1 vector artwork.

## Idle glossy upgrade
`idle/sheet.png` is a distinct 8-frame transparent 4×2 PNG atlas; `idle/sheet.webp` and `idle/preview.gif` are design previews. Mirrored on the legacy Brain idle path for current asset loading. Alpha matting from RGB generated art requires inspection.

## Illustrated Sleepy and Alarm candidates
- `alarm/` and `sleepy/` use individually illustrated 4×3 / 12-frame transparent source sheets and deterministic render scripts, not V1 flat SVG art. Runtime assets and metadata are mirrored into `assets/characters/brain/`.
- Alarm plays once (`loop=false`, 95ms/frame); Sleepy gently loops (`loop=true`, 180ms/frame).
- Current **7/15** states on Glossy V2, 78 frames. Remaining 8 states have V1 fallbacks and must never be described as completed glossy art. Human animation/phone QA still pending.
