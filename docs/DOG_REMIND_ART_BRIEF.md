# OneLife – Dog Remind Glossy V2 · source and release contract

**Status:** Source imported, runtime rendering and GitHub CI pending until verified. Original illustration candidate, not user-approved production art.

## Character / action
Use **the same Dog master** at `assets/characters-v2/dog/master.webp` (orange-apricot glossy puppy with floppy ears, cream muzzle/belly, pink cheeks, brown sparkling eyes, curled forehead tuft and soft tail). Twelve original illustration key poses: (1) friendly idle with gold bell, (2) spots new bell alert, (3) tilts head upward, (4) turns with smiling curiosity, (5) points at bell, (6) raises happy paw and rings bell, (7) small excited alert, (8) waves to user, (9) hops briefly, (10) gentle smiling landing, (11) one more friendly bell point, (12) returns to calm. Bell only indicates notification.

## Source and renderer
- `assets/characters-v2/dog/remind/sheet_illustrated.webp`: actual 4×3 RGBA frame atlas, 1024×768 (256×256 per frame).
- Source SHA-256: `19ce5b7b2031d528346b9d6ceedb995bee849a8ceadd8adb9969a9f4a5bbe9c0`; Git blob SHA is separate.
- Animation source catalog: `assets/characters-v2/animation_sources.json`. **125 ms per frame**, `loop=false`, bottom-centered anchor `(0.5,0.92)`.
- Deterministic renderer: `tools/render_glossy_character_animation.py`. Produces `sheet.png`, `preview.gif`, `metadata.json`, `qa_report.json` and updates manifest when GitHub Actions succeeds.
- Original generated illustration processed to remove near-white exterior and produce real alpha; no third-party character.
- Document face/ear/eye proportion QA and 64/96/144 pixel review. Source has fixed 12 acting poses but passing pixel-difference checks **does not** establish seamless or fluid motion.
- Review status: **human visual review pending; Android/iOS performance, reduced-motion and battery checks pending.**
- App behavior: use notification access only with consent. Non-intrusive cue, honor quiet hours and cooldown; no requirement to read private notification content by default.

## Acceptance before release
- [x] 12 independent illustrated poses prepared, original frame geometry locally checked
- [x] Source atlas imported to GitHub
- [ ] Renderer outputs and SHA verified on GitHub main
- [ ] GIF preview one-shot and no frame crop tested in GitHub CI
- [ ] Compare each frame side by side with Dog master, no design drift
- [ ] Android device 64px overlay, energy/reduced-motion and quiet hours validated
- [ ] Human approval of real animation, not just static frame count
