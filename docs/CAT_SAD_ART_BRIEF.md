# Cat Sad — frame-by-frame art handoff

**Character:** Glossy Lavender Cat, canonical `assets/characters-v2/cat/master.png`.

## 12 visual beats
1–2: curious concern and lowered ears. 3–4: shoulders droop and eyes soften. 5–6: gentle teary eyes, hands together. 7: hopeful gaze. 8: breathe out softly. 9–10: reassured expression. 11: short friendly smile. 12: composed, neutral cat.

This is a symbolic animation for gentle reassurance, **not an inference of depression or medical harm from phone use**. Do not auto-trigger sad expressions based solely on screentime.

## Source and QA
- 4 columns × 3 rows, 12 individual source poses; 256px cell, 170 ms/frame; one-shot.
- Original source SHA-256 `fc69b9241ee15a80bb73a754c2c36b6f8c31cef63a19a10f0fdf7a5147f4ebf2`.
- Pipeline: `tools/render_glossy_character_animation.py`, catalog `assets/characters-v2/animation_sources.json`.
- Technical checks: nonempty alpha, frame margins and adjacent pose differences (local checks only before GitHub Action).
- Approval: manually inspect 64/96/144px overlay, anti-aliased edges against dark/light, facial consistency, non-jarring one-shot, reduced motion and real Android battery budget; all pending.
