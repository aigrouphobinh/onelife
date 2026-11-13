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
The GitHub connector accepts UTF-8 source and Git objects but not local binary paths. A workflow was added to render and commit PNG/GIF on main; until its output files can be fetched from the repository, the binary assets must not be marked delivered on GitHub. The locally generated reminder raster sample is available as a download in the originating ChatGPT conversation.

## Verified production evidence
- GitHub Actions run 43523520219 completed successfully for 50 animation clips.
- At least one generated PNG/GIF file for each of cat, dog, robot, sprout was read back successfully via GitHub API.
- 10 screen SVG/PNG compositions validated by design-render workflow 43524137611. These are design mockups, not app screenshots.
- Remaining work: visual approval of every motion; reduced-motion, actual device, battery and accessibility checks.
