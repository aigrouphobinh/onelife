# Cat Strained — gentle screen-use nudge animation contract
**Status:** ORIGINAL SOURCE IMPORTED on main; runtime PNG/GIF and automated QA pending CI. Human/device art approval still pending. Follow `design/STYLE_LOCK_V2.md` and `docs/BRAIN_BALANCE_DESIGN.md`.

## Twelve original acting poses
1. Cat still alert and friendly.
2. Blink slows and tiny shoulders lower.
3. Long blink and slight head tilt.
4. Small cartoon sweat drop appears (one side only).
5. Ears sink modestly, tail relaxes.
6. Soft tired expression, small low paw gesture.
7. Gentle sigh; no alarming cracks or electrical damage.
8. Light calming breath, sweat drop decreases.
9. Cat slowly straightens, eyes open.
10. Friendly mild reminder gesture.
11. A neutral small smile returns.
12. Calm end pose; no forced laughter or fake medical cure.

## Visual contract
- 12 original RGBA 256×256 frames; 4 columns × 3 rows; `frameDurationMs=170`, `loop=false`.
- Subtle and non-shaming; never portray actual brain damage. No self-harm imagery, guilt, scary warning text, or flashing effect.
- At 64px, expressions must remain recognizable without tiny text. Meaning must be presented by companion accessible copy, not by face alone.
- Trigger only with opt-in usage access and a user-editable break goal, respect quiet hours and cooldown. When permission is denied show normal Idle, never infer use time.

## Import and acceptance
1. Draw actual state-specific poses. Do not crop poster overview or recolor an existing Brain.
2. Export source `assets/characters-v2/cat/strained/sheet_illustrated.webp`, calculate source SHA-256, catalog it, render PNG/GIF/JSON on main.
3. Verify 12 populated frames, clean alpha and 11 adjacent-pose differences; these checks do not prove seamless animation.
4. Human/device QA remains required (64/96/144px, low-end Android battery, accessibility, no medical implication). **No sprite is delivered by this document alone.**

## Source evidence
- 12 original illustrated poses generated for the OneLife Cat mascot in the approved Glossy Kawaii V2 style; not a repurposed Flat V1 sprite.
- GitHub source: `assets/characters-v2/cat/strained/sheet_illustrated.webp` (1024×768 with 12 256px RGBA cells, 4 columns).
- Source SHA-256: `8b67a102fb63f414a7ccb2ed7a8eaab5ae01259e2b91def43b78538281a772d7`.
- Local technical QA: 12 populated frames, 11 visibly different adjacent poses, bounding boxes at least 2px from edges, minimum adjacent RGB RMS 69.4. These checks do not establish visual acceptance or smooth continuous motion.
- Caution: This character is an optional *gentle reflection* of user-defined screen-use break goals, not a health metric or injury diagnosis.
