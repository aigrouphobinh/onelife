# OneLife — Mascot Asset QA & Production Gate

## Mandatory gate before app rendering
- [x] 5 original master vectors committed to main.
- [x] 12 original icon vectors committed to main.
- [x] 10 Brain animation SVG sheets committed to main (100 designed frames).
- [x] Frame timing and geometry metadata for Brain states committed to main.
- [x] Source-to-PNG/GIF renderer and GitHub workflow committed to main.
- [x] GitHub Actions produced PNG sprite atlases, GIF previews and SHA-256 manifests on main for all 50 clips.
- [ ] Manual art + real-device QA for 50 clips, including alpha, clipping, consistent baseline.
- [ ] Art direction approval for Brain master and expression preview.
- [x] 10 source + rendered clips each for cat, dog, robot and sprout (40 extra clips).
- [ ] Battery and reduced-motion fallback tests on Android hardware.
- [ ] Full dark/light UI compositing and small overlay readability.

## QA reference
Brain sprite atlas is 4 columns × 2–3 rows, 256×256 cell, state-defined frame count. Distinct vector frames include changing facial expression/eyelids, accessory props and animation offsets; review in PNG/GIF for visible movement. GIF previews are review tools, not production rendering format.

## Current blockers
Binary sprite PNG/GIF files and original WAV files have been read back from GitHub and verified on main. Outstanding blockers are human review of all 50 motion clips, real-device overlay visibility, reduced-motion behavior, battery/CPU profiling and platform permission tests. See docs/ART_DIRECTION_REVIEW.md.

## Verified production evidence
- GitHub Actions run 43523520219 completed successfully for 50 animation clips.
- At least one generated PNG/GIF file for each of cat, dog, robot, sprout was read back successfully via GitHub API.
- 10 screen SVG/PNG compositions validated by design-render workflow 43524137611. These are design mockups, not app screenshots.
- Remaining work: visual approval of every motion; reduced-motion, actual device, battery and accessibility checks.

## Sound QA
- [x] Original deterministic source generator tools/generate_sounds.py on main.
- [x] GitHub Actions run 43524688175 passed; 5 WAV source artifacts generated, and remind.wav read back from GitHub.
- [ ] Test peak amplitude, notification permissions, quiet hours, user mute, Android/iOS supported formats and playback routing.

## Design Review Lab / Asset QA pipeline (2026-11-14)
- [x] Interactive design viewer created: design/review/index.html (local PNG atlas playback, seek, theme toggle, 10-page screen gallery).
- [x] Automated QA report: design/review/reports/asset-qa.md — 50 clips / 500 frames, zero automated errors and warnings.
- [x] Five character contact sheets generated on GitHub main.
- [x] Additional static JS syntax / local asset validation added to CI.
- [ ] Artist and real-device review remains pending. Automated checks do NOT constitute visual acceptance.

## Dark mode output
- [x] Ten dark SVG/PNG screen compositions and checksum manifest published on main by GitHub Actions.
- [x] Design gallery toggles between actual light and dark screen images.
- [x] Dark screen dimensions and hashes added to automated asset QA.
- [ ] Human review of dark-mode contrast, Android status bar and bottom navigation accessibility.

## Brain Balance extension (2026-11-14)
- [x] 25 original vector state clips added to the original 50; 75 clips and 760 design frames total.
- [x] GitHub Actions mascot renderer generated 25 new PNG atlases, GIF previews and metadata on main (run linked in GitHub Actions).
- [ ] Extended automated asset QA must pass with 75 clips and 760 frames.
- [ ] Full visual and mobile-device review for all additional 25 clips, 64/96/144px and dark/light.
- [ ] UI concept for user-defined break goals, permission-denied and break/recovery sequences.
- [ ] Flutter runtime, local rules engine and OS permissions (NOT implemented).
See [BRAIN_BALANCE_DESIGN.md](BRAIN_BALANCE_DESIGN.md). `overloaded` is a fictional stress illustration, not damage diagnosis.

## 2026-11-14 Brain Balance added review assets
- [x] New sprite source and rendered binary: 25 wellbeing clips, all five characters (combined 75/760); on main.
- [x] 12 Brain Balance concept screens (6 states × light/dark) available under `design/wellbeing/`, using real sprite keyframes (mock data only).
- [x] QA now checks all 75 clips / 760 frames and both original 20 + Brain Balance 12 screen images.
- [ ] Human approval of emotional continuity, 64px readability and real-device tests.
- [ ] Flutter native usage tracking and real personalized rules (not implemented).

## V2 artistic acceptance gate
- [x] User selected glossy kawaii image as visual target.
- [x] Style lock and visual rebuild contract committed.
- [ ] Full-resolution verified reference image committed into GitHub (the chat-provided/generated artwork is not automatically a repo file).
- [ ] Glossy v2 Brain master approved.
- [ ] Glossy v2 animations and other character variants approved.
- [ ] Visual QA across all states, UI screens and device sizes.

**Do not confuse automated PASS on V1 sprites with art approval.**

- [x] Small 96×96 glossy reference thumbnail committed and Git blob hash verified. This is *not* a production master or complete user-selected board: `design/references/brain_glossy_thumbnail.webp`.

## 2026-11-14 Glossy V2 replacement status
- [x] Real high-detail 640×640 Brain master PNG pushed and mirrored to primary Brain master location.
- [x] New genuine glossy reminder sequence: 12 RGBA frames, 256px cells (4×3 atlas) pushed to main and mirrored to primary runtime path.
- [x] 12-frame GIF and WebP preview assets included, and metadata SHA256 matches newly generated atlas.
- [x] Generator safeguards glossy `brain/remind/sheet.png` from replacement by older flat SVG conversion.
- [ ] Full 15 Brain states are **not** glossy yet (only `remind` converted).
- [ ] Cat, Dog, Robot, Sprout have **not** been upgraded to V2.
- [ ] Frame-level visual / real Android device acceptance is pending.
