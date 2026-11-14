# OneLife — Dog Resting · Glossy Kawaii V2

**State:** `dog/resting` · **Status:** ART SOURCE MISSING; 0 delivered Resting clips. Do not mark complete from storyboards.

## Master and visual invariants
Use `assets/characters-v2/dog/master.webp`: glossy warm apricot-gold fur, floppy orange ears, little cream curl on forehead, shiny dark-brown eyes, round rosy cheeks, cream belly/paws and fluffy curved tail. Preserve face and silhouette proportions from Dog Idle/Remind/Alarm; this is the **same character**.

**DO NOT reuse Alarm art.** Two generated attempts on 2026-11-15 contained twin-bell clocks, symbols or captioned panels and were **rejected**. Resting must include no clock, bell, phone, push alert, labels, numbered captions, watermark, frame borders or rendered checkerboard.

## Twelve specific independently illustrated action poses
1. Puppy approaches a **small lilac cushion**, relaxed eyes.
2. Settles on the cushion, forepaws together.
3. Tail gently relaxes and ears hang softly.
4. Slow blink, slight downward head position.
5. Eyes close fully, tiny sleepy smile.
6. Gentle **inhale** — chest/body shape changes subtly.
7. Gentle **exhale** — shoulder and chest relax, without cloud that obscures face.
8. One floppy ear moves softly as the puppy stays resting.
9. Second relaxed breath with subtle chest change.
10. Tiny quiet smile in sleep, slight tail movement.
11. Eyelids half-open momentarily, no startled/excited response.
12. Return to initial resting pose for a **seamless loop**, no abrupt jump.

The purple cushion stays the **same size and position** across all 12 frames. Stable bottom-center anchor, no flickering details or whole-image distortion. Distinguish Resting from Sleepy (fatigue), Recovering (wake/stretches), Alarm (scheduled wakeup), Balanced (wellness reminder) and Idle (neutral).

## Production contract
- Separate painted key poses; 4×3 grid, 12 frames, 256×256 RGBA each, full 1024×768.
- 200 ms/frame; `loop=true`; no audio/flash in the image.
- Verify true transparency (not a baked white/checkerboard background), matte cleanup, 2px+ alpha margins, different adjacent visible frames, and **frame 11→0 loop seam**.
- Source: `assets/characters-v2/dog/resting/sheet_illustrated.webp`. Do not invent a SHA; pin actual SHA-256 after importing the correct approved art.
- Register `dog/resting` in `assets/characters-v2/animation_sources.json`; CI `tools/render_glossy_character_animation.py` produces `sheet.png`, `preview.gif`, `metadata.json`, `qa_report.json` and updates manifest/coverage.
- Show light/dark previews at 64, 96, 144px; human art review and Android low-end battery/performance remain pending. User's own screen-time break goals may trigger this animation later, but this art alone implements no usage-monitoring or scheduling API.
- No medical claims or fear-inducing “damaged brain” visuals.

## Gates
- [x] Narrative and source exclusion rules documented.
- [ ] Genuine 12-pose clean illustration reviewed.
- [ ] Source WebP committed to `main` with verified hash.
- [ ] GitHub renderer and coverage PASS, verified actual PNG/GIF.
- [ ] Manual silhouette/facial identity/loop review.
- [ ] Flutter mobile integration, reduced motion and low-end Android QA.

**No Resting clip exists until the source is imported and built.** This contract prevents claiming a rejected Alarm sheet is completed Dog Resting artwork.
