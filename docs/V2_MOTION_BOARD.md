# OneLife – Brain Glossy V2 Motion Board

Art baseline: design/STYLE_LOCK_V2.md. The approved look has a glossy, soft pink brain, rounded hands/feet, bright cheeks, sparkling dark eyes, glossy violet headphones. Keep exact facial ratios and camera angle across every key pose. Use original generated keyframes, not flat SVG reconstructions.

## Production order / frame acting

| Clip | Frames | Actual motion (per-frame art direction) | Current |
|---|---:|---|---|
| remind | 12 | Notices alert → surprised O-mouth → raises hand → points at yellow bell → bell swings → hops → settles | V2 raster candidate committed |
| idle | 8 | Two gentle inhale/exhale cycles, one authentic eye blink, hands relax, headphone gleam changes | Needs V2 illustration |
| happy | 10 | Eyes brighten, tiny cheek lift, two distinct hops, hands rise, sparkles, soft landing | Needs V2 illustration |
| alarm | 12 | Wakes suddenly, genuine startled face, reaches toward clock, bell shakes, settles | Needs V2 illustration |
| focus | 8 | Calm focused expression, looks down at desk/book, hands still, slow breathing | Needs V2 illustration |
| study | 12 | Opens book, follows page, turns page, reacts to idea, looks back at book | Needs V2 illustration |
| sleepy | 10 | Eyes droop, yawn, lean, close eyes, exhale, quiet Z particles | Needs V2 illustration |
| done | 12 | Surprise, success smile, raises checkmark, small jump, double fist pump, return | Needs V2 illustration |
| thinking | 8 | Looks up, tilts head, hands pause, question bubble changes, brief nod | Needs V2 illustration |
| sad | 8 | Slight disappointed droop, one slow blink, hand-to-cheek, calm compassionate recovery | Needs V2 illustration |
| balanced | 8 | Steady breathing, confident smile, small mint sparkle, relaxed sway | Needs V2 illustration |
| strained | 10 | Slight slouch, slower blink, one sweat drop, gentle tired breathing | Needs V2 illustration |
| overloaded | 12 | Comedic surprise, tiny purple static accents, wobble, steadies itself; avoid fear-based brain injury depiction | Needs V2 illustration |
| resting | 10 | Sits down, closes eyes, shoulders settle, calm inhale/exhale, slow peaceful particles | Needs V2 illustration |
| recovering | 12 | Opens eyes after rest, perks up, stretches, fresh expression, light sparkles, back to balance | Needs V2 illustration |

## Keyframe requirements

- All 15 clips must use real distinct poses; duplicate one still with scaling/rotation alone is not accepted.
- Export full transparent 256x256 RGBA cells, four columns per sheet, no grid and no text.
- Keep baseline bottom-center stable (anchorX 0.5, anchorY 0.92).
- Avoid clipping any hand, bell, headphone, sparkle, or shadow.
- Use a consistent frame flow (key pose → in-between → anticipation → main action → settle).
- Per-state playback is event-controlled; notifications must not repeat ringing forever.
- Store source, rights, checksum, frame count, duration and loop mode.
- Real-device view at 64px, 96px and 144px is mandatory before sign-off.
- Eyes, mouth and chubby silhouette must remain visibly recognizable at 64px.

## No false completion

Existing 75 V1 structure-valid clips remain *old flat art* unless explicitly promoted after artwork review. Brain master + remind clip are the only confirmed glossy V2 raster assets on main as of this document's drafting. Do not mark the other 14 state paths as V2 or link them from the V2 manifest until binary sprite art is actually committed and checked.
