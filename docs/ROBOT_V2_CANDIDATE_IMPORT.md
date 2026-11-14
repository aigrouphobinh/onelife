# OneLife Robot Glossy V2 — 10 illustrated candidate clip handoff

Checkpoint: 2026-11-15. Scope limited to Robot. Dog is handled separately.
This is a source-art handoff, NOT 10 clips registered on GitHub.

## Artwork staged outside this repository

A locally generated bundle named OneLife_Robot_V2_10_animations_candidates.zip
contains 10 independent pose-sheet candidates, source WebPs, raster PNG
atlases, preview GIFs, per-clip metadata and checksum QA. Original AI-generated
illustrations; no external purchased mascot asset. Every pose-source is 4 columns
of 256x256 RGBA cells and was locally checked for alpha, clipping, adjacent
visible frame difference, image dimensions and SHA-256. Visual/device approval
is pending. The bundle's binary bytes are NOT included in this commit, so none
of its clips should be counted by animation_sources.json or Flutter.

| State | Frames | Local source SHA-256 |
|---|---:|---|
| idle | 8 | 60b8c04c8430d84355c38413bb871b68975e75e0e891d67bc5de51b6efe707bf |
| remind | 12 | f1c9f2dd331125b4e8b3ee8bdd6cd3af2b5a13b9ed41cdd35d807d025b3711ea |
| happy | 12 | e292bc8588f96239a417701009c8fe9e1725148064976f1a7cb71a9f4bb4e87d |
| overloaded | 12 | 0cb5a9b1e9afd5e2a6a1df69742be04fed4d0c8c0efaee006286775d8a8d58bd |
| resting | 12 | 9b7861cf59e875f522ab673771141da3c70be821d15469350e08e43950c38109 |
| alarm | 12 | 57c26cf51c666b552ce2ed2e69c2b54dafd8f2072c9299d7a6f38ac3a88df300 |
| sleepy | 12 | e992b5cb0cb1c8a41fd1089f37931f72a4c8ef3cf04a413797162fcc39884b85 |
| recovering | 12 | c2cd776e890a922f422b91ccd09ee3b98549cbe33b3e589070300fb9dbccceaf |
| focus | 8 | 7f090931439de0078952277be333feb0c3bf17f85044b6aa3629e04a210da071 |
| study | 12 | 7b194c783c4444e316ce6b0f9825b2f02ae513a54e9648c0799af85ea925ac17 |

Total: 112 illustrated candidate frames. Local technical preflight: 10/10
source WebPs pass. This does not establish quality on 64px phone UI.

## Import into checkout, after source ZIP is available

    python tools/import_robot_v2_pack.py /path/to/OneLife_Robot_V2_10_animations_candidates.zip
    python tools/import_robot_v2_pack.py /path/to/OneLife_Robot_V2_10_animations_candidates.zip --apply
    python -m unittest discover -s tests -p 'test_import_robot_v2_pack.py'

--apply refuses conflicting source files/catalog entries; runs the existing
import_glossy_candidate.py per verified sprite and builds PNG/GIF/metadata.
Review every source, Git diff, QA report and checksum before pushing main.
Do not run the importer without the actual original binary ZIP.
Do not use a contact sheet, poster, static master or generated demo as motion.

No schedule changes: existing GitHub Actions retain their 15-minute checks.
After import: compare against robot/master.webp at 64/96/144px on light/dark,
then Flutter, reduced-motion/accessibility and physical phone battery review.
Missing 5 states (done/thinking/sad/balanced/strained) still need original art.
