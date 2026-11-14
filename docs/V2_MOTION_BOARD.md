# OneLife – Brain Glossy V2 Motion Board

Art baseline: design/STYLE_LOCK_V2.md. The approved look has a glossy, soft pink brain, rounded hands/feet, bright cheeks, sparkling dark eyes, glossy violet headphones. Keep exact facial ratios and camera angle across every key pose. Use original generated keyframes, not flat SVG reconstructions.

## Production order / frame acting

| Clip | Frames | Actual motion (per-frame art direction) | Current |
|---|---:|---|---|
| remind | 12 | Notices alert → surprised O-mouth → raises hand → points at yellow bell → bell swings → hops → settles | V2 raster candidate committed |
| idle | 8 | Two gentle inhale/exhale cycles, one authentic eye blink, hands relax, headphone gleam changes | V2 raster candidate committed (device review pending) |
| happy | 12 | Eyes brighten, tiny cheek lift, two distinct hops, hands rise, sparkles, soft landing | 12 new illustrated Glossy V2 poses committed, generated PNG/GIF verified by CI; human timing/phone review pending |
| alarm | 12 | Wakes suddenly, genuine startled face, reaches toward clock, bell shakes, settles | Original 12-frame glossy V2 illustrated source and PNG/GIF committed; device art review pending |
| focus | 8 | Calm focused expression, looks down at desk/book, hands still, slow breathing | Needs V2 illustration |
| study | 12 | Opens book, follows page, turns page, reacts to idea, looks back at book | Needs V2 illustration |
| sleepy | 12 | Eyes droop, yawn, lean, close eyes, exhale, quiet Z particles | Original 12-frame glossy V2 illustrated source and PNG/GIF committed; device art review pending |
| done | 12 | Surprise, success smile, raises checkmark, small jump, double fist pump, return | Needs V2 illustration |
| thinking | 8 | Looks up, tilts head, hands pause, question bubble changes, brief nod | Needs V2 illustration |
| sad | 8 | Slight disappointed droop, one slow blink, hand-to-cheek, calm compassionate recovery | Needs V2 illustration |
| balanced | 8 | Steady breathing, confident smile, small mint sparkle, relaxed sway | Needs V2 illustration |
| strained | 10 | Slight slouch, slower blink, one sweat drop, gentle tired breathing | Needs V2 illustration |
| overloaded | 12 | Comedic surprise, tiny purple static accents, wobble, steadies itself; avoid fear-based brain injury depiction | V2 original illustrated 12-frame candidate; QA and device review pending |
| resting | 10 | Sits down, closes eyes, shoulders settle, calm inhale/exhale, slow peaceful particles | Painted-pose montage candidate; dedicated resting body acting still needed |
| recovering | 12 | Opens eyes after rest, perks up, stretches, fresh expression, light sparkles, back to balance | Needs V2 illustration |

## Keyframe requirements

- All 15 clips must use real distinct poses; duplicate one still with scaling/rotation alone is not accepted.
- Export full transparent 256x256 RGBA cells, four columns per sheet, no grid and no text.
- Keep baseline bottom-center stable (anchorX 0.5, anchorY 0.92).
- Avoid clipping any hand, bell, headphone, sparkle, or shadow.
- Use a consistent frame flow (key pose → in-between → anticipation → main action → settle).
- Per-state playback is event-controlled; notifications must not repeat ringing forever.
- Store source, rights, checksum, frame count, duration and loop mode.
- Real-device view at 64px, 96px and 144px is mandatory before sign-off.
- Eyes, mouth and chubby silhouette must remain visibly recognizable at 64px.

## No false completion

Existing 75 V1 structure-valid clips remain *old flat art* unless explicitly promoted after artwork review. Brain master and idle/remind are committed; overloaded source WebP is committed and its PNG/GIF is generated in GitHub Actions. Human motion and phone acceptance are outstanding. Do not mark the other 14 state paths as V2 or link them from the V2 manifest until binary sprite art is actually committed and checked.

## 2026-11-14 candidate milestone
- `happy` (12 frames, 105ms) and `resting` (10 frames, 185ms) have PNG/WebP/GIF/metadata in V2 and live paths.
- Source is recombination of existing genuine painted Idle/Overloaded key poses, **not** new frame-by-frame authored illustrations; motion and visual sign-off are pending. The locally generated standalone Happy sheet is an art experiment and not the same file as the repository candidate.
- Validate 64px overlay, 96px widget, 144px in-app, transitions and reduced motion before treating these as production art.

## Glossy illustrated Happy correction · 2026-11-14
- The earlier `happy` source was a recombination of Idle/Overloaded frames. It is superseded by **12 separately illustrated glossy Happy poses** under `assets/characters-v2/brain/happy/sheet_illustrated.webp`.
- Source SHA-256: `0de17ddd7099186a2993ad41a2477298a49c0d5f75b5d0a7fc9939add949f689`.
- CI `glossy-illustrated-happy.yml` generated `sheet.png`, `preview.gif`, `metadata.json`, synced V2 and live paths, and validated all five active V2 states. This is NOT a phone-tested animation.
- A new **Alarm V2** 12-frame source was created locally from original glossy illustrations; local geometry/frame QA passed, but **its binary source is not yet on main** and is not counted among active V2 states. Sleepy and Recovering dedicated illustrated sources remain pending.

## 2026-11-14 – Alarm and Sleepy approved for technical QA, not art/device release

- `assets/characters-v2/brain/alarm/sheet_illustrated.webp`: 12 original glossy illustrated frames, source SHA-256 `b87db9c6277b6b61580356d5e3107f3b0969e84183438fcf55591ebe591fa5b3`; rendered by `tools/render_illustrated_alarm_v2.py` and verified by GitHub Actions.
- `assets/characters-v2/brain/sleepy/sheet_illustrated.webp`: 12 original glossy illustrated frames, source SHA-256 `b8d673383dab10d495dfcecf00e57e3ac186968712b6a0524d1b5eac937b480e`; rendered by `tools/render_illustrated_sleepy_v2.py` and verified by GitHub Actions.
- Both `sheet.png`, `preview.gif`, `metadata.json` and synced legacy-path assets were read back from GitHub. Base assets stay in `assets/characters-v2/brain`.
- Total active Brain Glossy V2: **7 of 15** states and **78** frames; remaining **8 states** in V1 fallback. The combined 5-character library remains **75 clips / 764 active frames** (technical checks only).
- `tools/generate_character_assets.py` now preserves all 7 live Glossy V2 states, so the older SVG renderer cannot replace them.
- Recovering is still **NOT** implemented in Glossy V2. Image-generator infographics and posters showing 15/15 completion are concept images only and are **not** valid spritesheets, source files or evidence of GitHub delivery.
- Human review of consistency, 64px legibility, smooth action timing and hardware tests remain pending.
