# Cat Balanced — glossy art direction and frame-by-frame contract
**Status:** PENDING SOURCE ART; not a counted animation. Follow `design/STYLE_LOCK_V2.md`.

## Twelve original acting poses
1. Neutral upright cat, soft smile, both paws on ground.
2. Small inhale, chest rises a little, eyes attentive.
3. Exhale, shoulder drop, head lowers slightly.
4. Long gentle blink, tail rests smoothly.
5. Both front paws settle, no screen gadget.
6. Small head tilt, relaxed expression.
7. A tiny mint sparkle appears near one side.
8. Slow steady breathing; sparkle fades.
9. Soft eyes and slightly lifted tail.
10. Small happy blink and gentle paw gesture.
11. Return to centered silhouette and neutral facial expression.
12. Repeatable closing pose aligned with frame 1, no scale or identity jump.

## Visual contract
- Genuine 12 individually illustrated RGBA 256×256 frames, four columns and three rows; `frameDurationMs=180`, `loop=true`.
- No lettering, fake transparency checkerboard, poster labels, ECG/clinical metric, badge claiming a health score or disease absence. Only optional subtle sparkles, never strobe.
- Preserve purple glossy kitten, eye highlights, white tuft/chest, pink inner ears, cheeks, curled tail and bottom-center anchor.
- Calm balance reflects **user-selected use goals**, not neurological recovery or a clinical reading.

## Import and acceptance
1. Save `assets/characters-v2/cat/balanced/sheet_illustrated.webp` only when the 12 true frames are available.
2. Verify SHA-256 and enter it in `assets/characters-v2/animation_sources.json` after production.
3. Run GitHub renderer, coverage and browser preview checks; inspect 64/96/144px, dark/light, alpha halos, loop stability and reduced-motion fallback.
4. Leave art/device signoff PENDING until on-device reviewer evidence. **Do not mark complete from this brief.**
