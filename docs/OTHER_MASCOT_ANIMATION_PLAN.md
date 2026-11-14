# OneLife – Remaining Glossy V2 mascot animations

**Current gate:** after mastering Brain (15 candidates), the 4 selectable characters (cat, dog, robot, sprout) each need 15 state-specific animations. Their original master PNG/WebP artwork exists on GitHub; a static master is not an animation.

## Actual state
- **Cat/idle:** eight original illustrated frames (source WebP), generated PNG/GIF via deterministic local workflow; automated QA before aesthetic/device sign-off.
- **Cat/remind:** twelve illustrated poses with a gold notification bell, imported as a candidate; independent art and real-device sign-off pending.
- **Cat/alarm:** twelve new illustrated glossy poses with a gold bedside alarm clock; source, atlas, GIF and metadata on main, technical QA PASS; visual/device review still pending.
- **Cat remaining:** happy, overloaded, resting, sleepy, recovering, focus, study, done, thinking, sad, balanced, strained: no individually illustrated clip committed yet.
- **Dog/Robot/Sprout:** all 15 character-specific state clips still missing.
- Total required: 60 illustrated state clips. After Cat Idle exists, 3/60 technically verified candidate assets and 57 remain. The existing V1 SVG art is NOT counted as Glossy V2.

## Per-state direction (distinct body acting, not one image with rotation)
| State | Cat | Dog | Robot | Sprout |
|---|---|---|---|---|
| idle | ear twitch, tail sway, blink | slow pant and tail wag | LED breathing and antenna glow | leaf sway, blink |
| remind | points bell with paw | nose nudges small bell | arm extends calendar | leaf points reminder |
| alarm | startled ears, bell shakes | jumps, floppy ears bounce | flashing alert eyes without strobe | leaves spring upright |
| happy | high paw hop, sparkles | tail spin, joyful bounce | LED smile and mechanical clap | twirls and leaf confetti |
| overloaded | droopy ears, comic worry lines | slowed ears and soft tired eyes | amber nonstrobing LED stress | leaves lower gently |
| resting | curled tail, slow eyes closing | lies down, relaxed breath | dims visor and docks | rests beneath leaves |
| sleepy | curls into a ball, yawns | one long yawn, slow blink | eyelid LED bars dim | drooping leaves with Z |
| recovering | stretches, ears pop up | puppy shakes, tail resumes wag | LEDs brighten gradually | leaves unfurl |
| focus | paws on small desk | steady posture with pencil | narrowed LED gaze at task | concentrated seated pose |
| study | page turn by paw | head turns with book page | projects tiny learning panel | holds and turns a book leaf |
| done | high-five, leaps once | celebratory paw and spins | checkmark pulse and clap | joyful stem bounce |
| thinking | tilted whisker, question cloud | head tilt and nose twitch | processing dots and head tilt | thoughtful leaf twirl |
| sad | empathetic ears down | soft eyes and one lowered ear | blue sympathetic eye state | gently bent stem |
| balanced | even breathing and mint sparks | calm tail rhythm | stable cyan heartbeat LED | bright healthy leaves |
| strained | tiny sweat, slower blink | ears droop slightly | warm amber caution LED | one tired leaf tilt |

## Technical requirements
- 256×256 RGBA cells, 4 columns; 8–12 original poses/state; metadata JSON and source SHA256.
- Keep full silhouette and accessories inside every frame. Align bottom-center anchor 0.5/0.92 and check animation jitter.
- PNG for runtime, source WebP for provenance, GIF only for review. Cache/decode only active atlas in Flutter.
- Reduced-motion still pose, mute by default, no medical diagnosis from screen usage.
- Each clip must have matching character identity, not a recolored Brain or repeated vector transforms.
- Do not mark any of the 60 clips done based on the previously generated 5×15 poster concept. That poster is an illustration, not a collection of real sprite files.

## Automated import
`assets/characters-v2/animation_sources.json` lists only verified original illustration sources. `tools/render_glossy_character_animation.py` validates hashes, dimensions, alpha and meaningful adjacent pose differences, outputs PNG/GIF/JSON and updates manifests. Do not insert art without rights/provenance and QA evidence.

## Remaining gates
Art reviewer must inspect 64/96/144px playback; device profiling on Android/iOS, quiet hours, native permission and Flutter sprite player are not complete. The multi-character animation feature stays open until these gates pass.
