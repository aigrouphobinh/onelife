# OneLife Glossy V2 - production migration status

Updated November 14, 2026. Source of truth: design/STYLE_LOCK_V2.md.

## Verified on GitHub main
- Versioned glossy Brain master: assets/characters-v2/brain/master.png
- Versioned remind animation: assets/characters-v2/brain/remind/sheet.png (12 RGBA frames)
- Live glossy Brain master: assets/characters/brain/master.png
- Live remind animation: assets/characters/brain/remind/sheet.png
- Versioned and live renders may differ by size, compression, and timing: validate each using its own SHA-256 metadata, not byte equality.
- Browser playback and side-by-side comparison: design/review/glossy-v2.html

## Remaining
- 14 other Brain states still use non-approved V1 vector art.
- Cat, Dog, Robot and Sprout still use V1 art.
- Real-device Flutter sprite runtime, battery and permission QA is not yet complete.
- The full-resolution 1024px master and 12-frame candidate generated in ChatGPT this turn are packaged separately and have NOT automatically been pushed as binary assets.

## Next acceptance gates
1. Review all 12 remind frames on light and dark at 64/96/144 px.
2. Draw truly unique idle, happy, resting and overloaded glossy art with consistent face/body/headphones.
3. Add state-specific sprite sheets and metadata only after transparent-edge QA.
4. Review human motion and color consistency; run QA on Android before calling V2 final.
