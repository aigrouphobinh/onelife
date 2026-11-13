# OneLife — STYLE LOCK V2 · Cute Glossy Mascot

**Status:** APPROVED ART DIRECTION from user-provided image, 2026-11-14.  
**Priority:** This visual reference supersedes the flat SVG mascot style. Existing V1 SVG/PNG sprite atlases are technical prototypes and **NOT final art**, regardless of their successful automated QA.

## 1. Immutable visual identity

The user's selected reference is the **canonical visual target**, not the flat sprites currently in `assets/characters/`.

- **Visual language:** premium kawaii / 2.5D chibi illustration; rounded, soft, squishy, candy-like glossy volumes; clean dark-purple outlines, subtle pink-purple shading and warm soft highlights.
- **Default Brain:** full pink brain silhouette; gently recognizable lobes; shiny dark large oval eyes with white catchlights; large blush circles; small happy mouth; two tiny rounded hands and two short feet; oversized luminous violet over-ear headphones.
- **Expression:** emotions expressed jointly by face, posture, arm gesture, pupils, accessories, bounce and particles—not merely swapping an SVG mouth.
- **Character consistency:** same face proportions, blush position, body-head ratio, earcup thickness, light direction and palette in every frame. Keep stable original identity across each of the 15 emotional/action states.
- **Art quality:** clear 256px transparent source with soft anti-aliasing; 512px/1024px source layers recommended; visually recognizable at 64px overlay and 96px widget.
- **UI match:** dark violet gradient or soft lilac backgrounds, translucent/light cards, soft shadows, rounded cards (~18–24dp), pastel-purple accents, visually polished custom icons with consistent lighting.
- **Palette (approximate, not a replacement for the supplied image):** brain #FFC1E0 / #F7A7CF; deeper outline #6B3D89; headphones #9A69E8 / #6E42C5; blush #F57FA8; UI #34244E / #7E5ED3 / #EEE7FB.

## 2. Mandatory NO-GO conditions

- Flat monochrome vector, emoji mascot or simplified circles **may not** replace final high-fidelity character art.
- No stretching/squashing by scripts as a substitute for hand-drawn/interpolated action poses.
- No checkerboard painted into PNG transparency, cut-off limb, inconsistent face/ears/headphones, watermark, generic stock creature, random color drift, or tiny illegible accessories.
- Do not declare visual approval from PNG count, hash, CI success or GIF technical existence.
- No finished-status text inside concept boards that falsely claims code or assets were delivered.

## 3. What to rebuild first

1. **Brain master v2** in 1024×1024 or higher, truly transparent source, original project art, maintaining the user-supplied glossy look.
2. **Expression proof sheet:** idle, happy, remind, alarm, focus, study, sleepy, done, thinking, sad + balanced, strained, overloaded, resting, recovering.
3. **Three pilot animations**: idle (8 distinct frames), remind (12 distinct frames), overloaded (12 distinct frames), resting (10 distinct frames). These must show genuine frame-by-frame acting and be checked at 64px/96px/144px.
4. After explicit human art approval, complete the remaining 11 Brain clips, and only then convert the other four selectable characters to the same visual standard.
5. Produce home/onboarding/habits/characters pages at light/dark variants incorporating the actual v2 raster character, not a flat vector re-draw.

## 4. File and rendering contract

Candidate output:
```text
assets/characters-v2/
  brain/master.png
  brain/expressions.png
  brain/idle/sheet.png + metadata.json + preview.gif
  brain/remind/sheet.png + metadata.json + preview.gif
  brain/overloaded/sheet.png + metadata.json + preview.gif
  brain/resting/sheet.png + metadata.json + preview.gif
  cat/...
design/references/  (visual references and provenance)
```

- Source master: layered PNG or equivalent editing source; no flattened checkerboard.
- 256×256 RGBA frame cells, 4 columns, 8–12 frames per state as per `docs/CHARACTER_ANIMATION_SPEC.md`.
- Do not overwrite V1 before v2 art has been visually approved and the runtime asset resolver has a tested migration plan.
- Store provenance/rights info and checksums in `docs/ASSET_REGISTER.md`; track source prompt/seed when available.
- Add manual *per-state* screenshot comparison against the selected reference and a visual acceptance checkbox; automated pipeline checks geometry/alpha only.

## 5. Visual acceptance criteria

- Same instantly recognizable cute pink brain as the image user selected, without losing gloss, detail or warmth.
- Every frame preserves same proportions and recognizable identity; no flicker or broken motion.
- Each emotion has unique body action—not just bob/rotation.
- 64px: eyes, cheeks and status should still read; important meaning is also available in text.
- Subtle non-flashing wellness overload graphic. **Never** present actual brain injury / mental health diagnoses from screen time.
- Side-by-side visual review by user is mandatory; no visual completion by code agent self-approval.

## 6. Reference availability

The source art is in the user's ChatGPT conversation. A processed candidate extracted from the previously generated glossy 12-pose Brain image exists as a conversation artifact; it is **not** automatically part of this GitHub repository. Its transparency mask is provisional and requires edge cleanup. Import it as a v2 reference, never claim it was uploaded or approved unless verified by GitHub readback.

**Decision:** Freeze the existing V1 flat mascot rendering for production. Prioritize visual consistency and original glossy asset production before further Flutter feature implementation.
