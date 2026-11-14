# OneLife – Cat Overloaded: art acceptance brief

**Status:** Missing an approved independent pose sheet. Do not count as a completed fifth Cat animation.

## Purpose
An opt-in, compassionate digital-wellbeing indicator shown after a user-defined screen-use goal is exceeded. The cat looks mildly overwhelmed in a **playful, temporary** way; it does not imply actual brain damage, medical diagnosis, addiction or punishment.

## 12-frame narrative
| Frame | Acting and props |
|---|---|
| 01 | Cat seated at a small purple laptop, relaxed eyes |
| 02 | Looks toward a growing task stack |
| 03 | Ear tilts and brows narrow |
| 04 | A small blue sweat bead appears |
| 05 | Both ears lower, one soft stress zigzag |
| 06 | Cat lifts its paws, eyes briefly squeezed |
| 07 | Cartoon dizzy swirl with clearly non-flashing motion |
| 08 | Cat briefly lowers onto the desk, no severe distress |
| 09 | Eyes close, breathing starts |
| 10 | Deep, slow exhale; effects fade |
| 11 | Eyes reopen and sparkles replace stress marks |
| 12 | Cat smiles, ready to ask whether to take a break |

## Non-negotiable art rules
- Follow **Glossy Kawaii V2** master exactly: lilac fur, purple outline, shiny eyes, blush, curled tail and same face proportions.
- Clean 4×3 atlas, exactly 12 independent poses, each 256×256 RGBA, no visible labels/panel borders/checkerboard in final pixels, no clipped props.
- No laptop UI details that look like real user data. No alarm clock in Overloaded.
- Static-frame reduced-motion equivalent and text-based accessible explanation.
- Optional opt-in only; never derive 'neurological harm' from screen-time duration.
- Source provenance/rights, SHA-256, all frames visually verified at 64, 96, 144 and 256px.
- The existing `design/references/cat_strained_overloaded_keyposes.webp` is only a **two-pose reference**; design posters and 2-keyframe transformations cannot be counted as independent animation art.

## Build and QA
When an actual illustrated 12-frame WebP source exists, append its verified sha256 and `generationClass: independently-illustrated-pose-sheet` to `assets/characters-v2/animation_sources.json`. Then run `tools/render_glossy_character_animation.py` and `tools/check_mascot_coverage.py`. A CI PASS is structural only; issue #31 remains open pending visual/device signoff.
