# OneLife — Mascot Asset QA & Production Gate

## Mandatory gate before app rendering
- [x] 5 original master vectors committed to main.
- [x] 12 original icon vectors committed to main.
- [x] 10 Brain animation SVG sheets committed to main (100 designed frames).
- [x] Frame timing and geometry metadata for Brain states committed to main.
- [x] Source-to-PNG/GIF renderer and GitHub workflow committed to main.
- [ ] GitHub Actions output PNG sheet, preview GIF, SHA-256 verified on main.
- [ ] Real renderer QA for all 10 Brain clips, including alpha, clipping, consistent baseline.
- [ ] Art direction approval for Brain master and expression preview.
- [ ] 10 animations each for cat, dog, robot and sprout (40 clips remaining).
- [ ] Battery and reduced-motion fallback tests on Android hardware.
- [ ] Full dark/light UI compositing and small overlay readability.

## QA reference
Brain sprite atlas is 4 columns × 2–3 rows, 256×256 cell, state-defined frame count. Distinct vector frames include changing facial expression/eyelids, accessory props and animation offsets; review in PNG/GIF for visible movement. GIF previews are review tools, not production rendering format.

## Current blockers
The GitHub connector accepts UTF-8 source and Git objects but not local binary paths. A workflow was added to render and commit PNG/GIF on main; until its output files can be fetched from the repository, the binary assets must not be marked delivered on GitHub. The locally generated reminder raster sample is available as a download in the originating ChatGPT conversation.
