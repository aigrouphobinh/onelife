# Robot Thinking — alternate artwork candidate (not registered)

**Candidate produced: 2026-11-15.** This is an **alternate, non-canonical**
visual reference. Another workstream has already registered Robot Thinking on
`main` with source SHA-256
`ed3a1577a6996a02361d0939b6fcfd5047c4daa8e937bae751060f66f5b1626a`.
The alternative candidate below has a **different SHA** and must not be
auto-imported, overwrite the existing source, or increase clip coverage.
This is a practical handoff for potential human side-by-side art review. It is **not** evidence of an imported or
human-approved clip. The binary source is available as the conversation
attachment `OneLife_Robot_Thinking_V2_candidate.zip`, not in this repository.
Do not register or increment coverage for this alternative. The registered
Thinking clip must be retained unless a separately approved replacement is made.

## Acting and appearance

Original twelve-pose, four-column sprite source for the existing white/blue
Glossy Kawaii robot with a navy screen-face, cyan LED eyes, articulated hands,
blue core, headset-like side pods and antenna orb. The sequence is:

| Frame | Distinct action |
|---|---|
| 00 | Friendly standing neutral |
| 01 | Eyes glance upward with curiosity |
| 02 | Head tilts as the robot notices a question |
| 03 | Hand touches chin, thinking |
| 04 | Brows tighten, considering an option |
| 05 | Arms fold in concentration |
| 06 | Head tilt and posture rethink |
| 07 | Eyes close, fingers touch temples |
| 08 | Both hands brighten with anticipation |
| 09 | Aha smile and positive gesture |
| 10 | Happy pointing gesture with small idea accents |
| 11 | Return to friendly neutral pose |

No text, labels, poster borders, or fake opaque checkerboard belong in the
source atlas. Visual choices are playful, not health diagnoses.

## Local source and technical evidence

- Target source: `assets/characters-v2/robot/thinking/sheet_illustrated.webp`.
- Original illustration generated for this project; generation ID:
  `856cae8b-fa35-417a-b7b2-c5e1df51507f`.
- AI-generated candidate, platform terms apply; do not assert a stock-art
  license or human approval.
- **Exact source WebP SHA-256:**
  `4fc02e26d68104da52f0cd048ae9faf5b970b68a4a5a4c8976135760526cd375`.
- WebP size: 648,664 bytes. RGBA, 1024 × 768 px; 12 frames in 4 × 3
  grid, each cell 256 × 256.
- Suggested `frameDurationMs=150`, `loop=true`, anchor (0.5, 0.92).
- Local per-frame true-alpha check: every cell has more than 10% fully
  transparent pixels; minimum visible-character edge margin 3 px.
- Local 11 adjacent-frame differences: minimum RGB RMS 57.17 on an opaque
  pale matte. No duplicate adjacent poses.
- GIF review: 12 frames at 150 ms, infinite loop.
- `tools/import_robot_v2_pack.py` `validate_pack()` accepted the
  one-state ZIP in dry-run. Light/dark desktop previews were created.
- **Still pending:** comparison with the canonical Robot master at small
  sizes, human art approval, Flutter preview, real device QA.

## Optional import procedure only if an art reviewer explicitly approves replacing the registered source

The ZIP contains `BUILD_REPORT.json` and
`thinking/{sheet_illustrated.webp,sheet.png,preview.gif,metadata.json,candidate_qa.json}`.
The following import commands are archival reference only. **Do not run against the current `main`** because Robot Thinking is already registered and the importer correctly rejects duplicates. If a reviewer elects to replace that source, use a deliberate migration with updated art approval and tests. Original procedure:

```bash
python tools/import_robot_v2_pack.py /path/to/OneLife_Robot_Thinking_V2_candidate.zip
python tools/import_robot_v2_pack.py /path/to/OneLife_Robot_Thinking_V2_candidate.zip --apply --version 2.42.0-illustrated-candidate
python tools/check_glossy_source_catalog.py
python tools/render_glossy_character_animation.py --character robot
```

Before committing, compare the imported source hash with the value above,
inspect the 64/96/144px light/dark sprite preview and verify the generated
PNG/GIF/metadata and QA. Preserve `productionReady=false` and do not
overwrite already registered Robot states. The other pending Robot states
remain `sad`, `balanced` and `strained`.

This handoff does not alter or duplicate the existing GitHub Actions schedule.
