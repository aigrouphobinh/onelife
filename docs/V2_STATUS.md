# OneLife – Brain Glossy V2 verified asset status (2026-11-14)

**Source of truth:** `assets/characters-v2/brain/manifest.json` plus `design/review/glossy-v2.html`. Never use promotional images or outdated README percentages as evidence of actual delivery.

## Active states (7/15, 78 frames)

| State | Frames | Art source | Delivery | Art/device review |
| --- | ---: | --- | --- | --- |
| idle | 8 | Glossy V2 raster | Active PNG/GIF on main | Pending |
| remind | 12 | Glossy V2 raster | Active PNG/GIF on main | Pending |
| overloaded | 12 | Illustrated glossy V2 | Active PNG/GIF on main | Pending |
| happy | 12 | Illustrated glossy V2 | Active PNG/GIF on main | Pending |
| resting | 10 | Glossy key-pose montage | Active PNG/GIF on main, needs dedicated in-betweens | Pending |
| alarm | 12 | Illustrated glossy V2 | Active PNG/GIF on main | Pending |
| sleepy | 12 | Illustrated glossy V2 | Active PNG/GIF on main | Pending |

## Next art assets (8 not yet on V2)
- `focus`: calm concentration, book/screen attention
- `study`: reading and page turns
- `done`: distinct positive achievement action
- `thinking`: reflective gaze and thought bubble
- `sad`: gentle empathetic response, never shaming
- `balanced`: calm and cheerful personal-goal visualization
- `strained`: gentle tiredness, no clinical diagnosis
- `recovering`: recovering *mood* / refresh after a break, never neurological repair claim

The latest generated "all completed" infographic is **not** a runnable asset and must not count toward the manifest.

## Validation evidence
- `glossy-illustrated-alarm.yml` run 43543232807: PASS.
- `glossy-illustrated-sleepy.yml` run 43544289860: PASS.
- `mascot-assets.yml` uses protected V2 overrides and updated 156-frame Brain total: latest run PASS.
- `tools/check_design_assets.py` and `tools/check_glossy_v2_assets.py`: 75 clips, 764 active frames, 7 V2 states, zero automated errors/warnings.
- Art/device QA and iOS/Android runtime tests: **NOT DONE**.

## Exit gates
Do not migrate to Flutter until manually reviewed at 64/96/144 logical pixels with light/dark background, reduced-motion stills, loop continuity, CPU/battery tests, and permissions. Source artwork alone cannot prove these requirements.
