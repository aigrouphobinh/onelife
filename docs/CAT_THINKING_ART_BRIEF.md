# Cat Thinking — Glossy Kawaii V2 Motion / QA

**Asset status:** 12-pose original illustration candidate. Do not mark artistic approval based on automated checks.

## Keyframes
1. Attentive idle; 2. curious sideways glance; 3. eyes up and paw to chin; 4. surprise; 5. searching; 6. question mark; 7. closed-eye concentration; 8. slight head tilt; 9. relaxed exhale; 10. lightbulb and raised paw; 11. delighted sparkles; 12. peaceful smile.

## Rendering
- Source: `assets/characters-v2/cat/thinking/sheet_illustrated.webp`, 1024×768 RGBA, 4×3, 256 px/cell.
- FPS ~6.67 (150 ms/frame), loop true; no text/labels, decorative icon particles allowed.
- Renderer: `tools/render_glossy_character_animation.py` and catalog `assets/characters-v2/animation_sources.json`.

## Acceptance
- [x] Source atlas generated from distinct illustrated poses; 12 of 12 nonempty RGBA cells
- [x] Local image-QA: 11/11 adjacent frame changes, minimum alpha padding ≥2 px
- [ ] GitHub Actions source validation, runtime PNG and GIF, manifest and contact-sheet update
- [ ] Human art continuity review on light/dark backgrounds, including white fringe and scale 64/96/144 px
- [ ] Flutter renderer and device battery/accessibility tests

**Known limitation:** These are illustrated storyboard poses, not an independently hand-tweened seamless animation; structural QA does not establish smooth acting or production-ready art.
