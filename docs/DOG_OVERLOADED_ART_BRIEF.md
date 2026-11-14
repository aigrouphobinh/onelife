# OneLife — Dog Overloaded Glossy V2 · Production brief

**Status:** art source NOT created, 0/1 Dog Overloaded animation. This specification is not a completed sprite.

## Visual identity and behavior
- Use actual `assets/characters-v2/dog/master.webp` warm golden-apricot dog, soft floppy ears, cream forelock/belly/paws and expressive brown eyes.
- A soft, optional screen-time nudge: slower blink, subtle tired posture, ears lower, one tiny cartoon sweat drop, the dog gently suggests a short break.
- Avoid injury, medical claims, alarm clocks, blame, flashing/strobe effects, labels or poster-style sheets.
- Return to a calm pose, **not** to high-energy celebration; this is different from Resting/Sleepy/Alarm.

## Required 12 original illustrated frames
1. Friendly neutral seated dog
2. Slightly slower blink
3. Ears begin drooping
4. Tiny sweat drop at one cheek
5. Small head incline
6. Tired but gentle eye expression
7. Little sigh gesture
8. Forepaw suggests a break
9. Sweat drop fades, breathing relaxes
10. Ears rebound slightly
11. Neutral small smile
12. Quiet settled final pose

## Output and acceptance
- 12 distinct illustrated 256×256 RGBA frames, 4 columns × 3 rows, source `assets/characters-v2/dog/overloaded/sheet_illustrated.webp`.
- 150ms/frame, one shot; transparent background; SHA-256 pinned from actual source.
- Register in `assets/characters-v2/animation_sources.json`; verify CI-generated PNG, GIF, manifest, metadata and coverage.
- Distinguish automatic geometric QA from artistic QA at 64/96/144px and on-device performance. Do not count this state until source is committed and renderer succeeded.
- Screen-time feedback should be opt-in and user-configurable; do not suggest diagnosing a damaged brain.
