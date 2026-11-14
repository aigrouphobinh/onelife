# OneLife — Cat Sleepy Glossy V2 · Art production brief

**State:** `cat/sleepy` | **Status:** artwork NOT committed as a runtime sprite. The poster/infographic attempts were rejected. Do not count them in animation coverage.

## Visual invariant
Use the actual [Cat V2 master](../assets/characters-v2/cat/master.webp) and the approved, glossy reference style in [STYLE_LOCK_V2](../design/STYLE_LOCK_V2.md): lavender fur, pink ears and cheeks, white forehead tuft, rounded paws, long curled tail, rich violet eyes and outlines. No phone required once sleeping. Do NOT recolor a Brain mascot or flatten into generic SVG.

## 12 acting keyframes (one full 4×3 sprite sheet)
1. Cat sits calmly, eyes bright, relaxed posture.
2. First long blink, slight ear droop.
3. Eyes half-closed, tail lowers gently.
4. Small yawn; mouth opens, paw begins rising.
5. Wider yawn with paw before mouth.
6. Finishes yawn, eyelids heavy.
7. Chin dips; sleepy wobble, tail curls inward.
8. Eyes close, body leans gently on forepaws.
9. Curl on soft lavender cushion, slow breathing.
10. Remains resting with small visible inhale.
11. Gentle exhale; ears move slightly without waking fully.
12. Returns to calm sleepy curl matching frame 9 for a seamless resting loop.

The animation is a **sleepy/rest loop**, not a moralizing screen-time penalty. No sharp flashes, bells, clocks, spoken narration, watermark, labels, numbers, poster border, pre-rendered checkerboard, or unrelated props.

## Asset contract
- `assets/characters-v2/cat/sleepy/sheet_illustrated.webp`: genuine transparent RGBA 1024×768, 4×3 equal cells, each 256px.
- `assets/characters-v2/animation_sources.json`: add verified source SHA256 only after successful review.
- Suggested duration 180ms/frame, loop true, anchor (0.5, 0.92).
- `tools/render_glossy_character_animation.py` renders `sheet.png`, `preview.gif`, `metadata.json`, `qa_report.json` and updates Cat manifest and coverage. Do not manually inflate counts.
- `design/review/glossy-cat-idle.html` must include it before CI can pass.

## Acceptance
- 12 clearly different, logically connected poses with stable face/body proportions.
- No frame clipping, alpha halo, text/badge contamination, background grid or cellphone glued to sleeping paws.
- 64/96/144px light and dark review, no unintended scale jumps, seamless resting cycle.
- Human art approval and Android battery/reduced-motion tests remain separate gates.
