# Robot Glossy V2 — image asset handoff

Scope: **Robot only**. Dog is being handled separately. Style authority:
`design/STYLE_LOCK_V2.md`; tracker: issue #33.

## Verified baseline (2026-11-15)

- Source coverage on main before this handoff: **27/60** (Cat 15, Dog 12, Robot 0, Sprout 0).
- The current conversation has a locally generated **Robot Idle** candidate:
  `onelife_robot_idle_8frame_candidate.webp` (1024×512, 8 poses,
  4 columns, 256×256 cells, 140ms, loop). Local candidate QA reported
  SHA-256 `b51926b79a96fd138ed2825282cc75f9539f4a60bdf3872e2d43762ba90858f0`.
  **The image binary has NOT been committed**; do not count this as sourced.
- Nine additional local Robot concept sheets exist: remind, alarm, happy,
  overloaded, resting, sleepy, recovering, focus and study. They are
  **concept images, not validated/registered source sprites**.
- Remaining planned states: done, thinking, sad, balanced, strained.

## How to promote one completed image

1. Confirm the exact Robot identity against `assets/characters-v2/robot/master.png`
   (or the existing canonical Robot master). Reject clipped antennae,
   halo artifacts, noisy matte, missing props and pose discontinuities.
2. For 4×3 RGBA concept sheets, run:
   `python tools/prepare_robot_sprite_candidate.py INPUT.png --output /tmp/robot_state.webp`.
   This rejects art that touches source tile boundaries; never quietly
   scale away missing antennae or cut-off hands.
3. Run `python tools/check_sprite_candidate.py /tmp/robot_state.webp`.
   Every frame must have real alpha, clear margins and visibly distinct poses.
   If QA fails, fix/re-illustrate the source; **do not bypass the gate**.
4. Compute `sha256sum /tmp/robot_state.webp` and import:
   `python tools/import_glossy_candidate.py --character robot --state STATE --source /tmp/robot_state.webp --expected-sha256 SHA256 --version 2.31.0-illustrated-candidate --frames 12 --frame-duration-ms 140`
   (use `--loop` only for genuinely looping actions).
   For Idle, import the original 8-frame WebP directly with `--frames 8`.
5. Commit the source, generated PNG/GIF/metadata/QA/manifest and catalog
   changes together to `main`; verify the commit and CI before counting.
   Keep `productionReady=false` until human art and phone review.

## Status policy

Do not count a ChatGPT image, concept board, passing GIF or code-only
commit as a delivered Robot clip. A Robot state counts as a sourced
illustration only after its **binary** and exact checksum are on main.
Real-device approval is a separate gate.
