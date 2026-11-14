# OneLife — Cat Recovering Glossy V2 Art Review
**Status:** Source imported as a candidate. Automated sprite QA and Github workflow are separate from manual approval.

## Art intention
A gentle one-shot from an already sleeping, lavender chibi cat to refreshed alertness:
1–4: curled on star pillow; tiny breath and movement
5–6: stirs, paw moves, yawns gently
7–8: eyes open gradually, ears lift
9–10: settles into sitting posture
11–12: soft joyful paw movement and smiling alert expression

The 12 poses originate from a single original generated illustration, then have been **reordered** to keep the animation sequence meaningful. Each source pose is separately illustrated. Do not claim that animation is perfectly smooth until visual review at 64, 96, 144, 256 px.

## Animation inputs
- Source: `assets/characters-v2/cat/recovering/sheet_illustrated.webp`
- SHA256: `b5c6b28a0f096424d80d281ded5187bacdf84814aecded4ff00855ba56a344a5`
- Frame geometry: 4 columns, 3 rows, 256×256 RGBA
- Frame duration: 115 ms, `loop=false`, anchor (0.5,0.92)
- Technical source of truth: `assets/characters-v2/animation_sources.json`

## Release gates
- [ ] Human approve image identity and state sequence; no sudden pillow jump, ghosting, baked checkerboard or white halo on dark mode
- [ ] 64px preview legibility, reduced-motion static alternative
- [ ] Android/iOS runtime and battery tests
- [ ] No health/brain-damage statements from animation
