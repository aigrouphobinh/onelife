# OneLife — Dog Sleepy · Glossy Kawaii V2 production contract

**State:** `dog/sleepy` · **Status:** source animation NOT imported. Do not count any poster, Happy sheet or other character's poses as Sleepy.

## Character identity

Use `assets/characters-v2/dog/master.webp` and the verified `dog/idle` atlas as the exclusive appearance references: apricot-gold glossy coat, floppy ears, cream forehead tuft, cream muzzle/belly/paws, rosy cheeks, oversized sparkling brown eyes and fluffy curled tail. Every frame must remain the same character with a stable bottom-center anchor.

**Differentiation:** Sleepy represents the transition toward fatigue; it is NOT Happy (jumping, hearts, confetti), Resting (static lavender cushion and slow breathing), Recovering (waking up) or Overloaded (screen-time break nudge). No clocks, bells, phones, laptops, books, hearts, flowers, numbers, titles, fake transparency or panel borders.

## Twelve distinct frame-by-frame poses (4×3)

| Frame | Acting direction |
|---|---|
| 00 | Dog neutral and gently alert; no sleep marks |
| 01 | Slightly slower blinking and lowered eyebrows |
| 02 | Eyelids half-closed, ear tips relax |
| 03 | First small yawn, head tips forward |
| 04 | Mouth opens in a larger natural yawn, eyes closed |
| 05 | Mouth closes; eyes flutter halfway |
| 06 | Shoulders lower; little forepaws draw closer |
| 07 | Head droops slightly; tail stops wagging |
| 08 | Light sleepy sway with ears following slowly |
| 09 | Eyes close fully, tiny relaxed smile |
| 10 | Brief sleepy micro-blink, posture steady |
| 11 | Calm sleep-ready settled pose, no forced jump to cheerful Happy |

## Animation contract

- Original **individually illustrated** source cells: 12 × RGBA 256×256, clean 1024×768 atlas arranged 4 columns × 3 rows.
- WebP source: `assets/characters-v2/dog/sleepy/sheet_illustrated.webp`. Compute the SHA-256 of the **real uploaded file** and register in `assets/characters-v2/animation_sources.json`.
- Suggested playback: 180ms per frame, `loop=false`; transition after ending should be `resting` or `idle` according to user intent, not an infinite fatigue loop.
- No distortion when the dog curls or yawns; ears, nose, mouth, chest, paws and tail retain identity. Include 2px+ transparent margins on all frame edges; no cut-off tails.
- Export PNG, GIF and metadata using `tools/render_glossy_character_animation.py`. Renderer must confirm source checksum, 12 nonempty frames, 11 visually changed adjacent pairs, proper GIF one-shot, correct dimensions, animation registration and coverage.
- Human art direction sign-off: visual inspection at 64px, 96px and 144px on light and dark backgrounds, including frame continuity, eye details, and alpha fringe cleanup; no screenshot-based approval.
- Mobile sign-off: reduced-motion preference, low-end Android FPS/battery and memory review, and UX confirmation that warnings are optional, quiet-hour aware and never shame users. This is **art only**; phone usage tracking and scheduling are separate software work.

## Acceptance checklist

- [ ] 12 Sleepy-specific original poses generated (NOT Happy/reused)
- [ ] Same Dog master geometry, eye color, muzzle, ears and tail
- [ ] Actual RGBA source has been visually reviewed and uploaded to main
- [ ] Correct source SHA-256 registered
- [ ] CI-generated PNG, GIF, metadata and coverage PASS and read back from GitHub
- [ ] Seam/one-shot pacing, reduced-motion and real-device QA performed
- [ ] Human approval for use in production

## Attempt record

2026-11-15: An attempted image generation after Dog Happy reproduced a **Happy celebration sheet** with hearts/confetti/music/flowers, not sleepy poses. It is rejected as a Dog Sleepy source and must not be added to the asset registry or coverage. Generate a new sheet according to the storyboard above.
