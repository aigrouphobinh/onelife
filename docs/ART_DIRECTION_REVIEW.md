# OneLife — Art Direction Review & Acceptance (v1)

**Status: REVIEW REQUIRED.** This is a design checklist for an art reviewer and a later real-device test; it is not a certification.

## Evidence already in repository
- Five original mascot master vectors: Brain (pink headphones), Cat (lavender ears and whiskers), Dog (orange floppy ears), Robot (cyan LED face) and Sprout (green leaves).
- Ten expression states for each character; 50 source animation sheets, 50 PNG atlases, 50 GIF review clips and SHA-256 metadata (500 frames total).
- Five deterministic expression contact sheets at design/review/contact-sheets/.
- Ten 390 × 844 design compositions at design/screens/.
- Five optional, default-muted, original notification WAV cues.
- Automated asset report: design/review/reports/asset-qa.md — covers dimensions, frames, file integrity, not art approval.
- Interactive HTML animation review: design/review/index.html — source-image playback, frame stepping, light/dark test.

## Visual review observations (from the still contact sheets)
- Mascot silhouette and head/face styles remain recognizable across states.
- Happy, sleepy, done and sad appear to have visibly different eyes/mouth; reminder/alarm/study/focus are distinguished by small accessories.
- At overlay size (64 logical px), the tiny props (bell, question mark, book and timepiece) may become hard to identify; verify real-size previews rather than extrapolating from the 900px contact sheets.
- Dog and Cat silhouettes have relatively simple body language in sample frames; their tails/ears should be checked frame by frame for genuinely character-specific action.
- Brain looks close to the default product identity, but requires review at both light and dark backgrounds, with full movement rather than keyframe stills.

## Manual acceptance procedure
1. Open design/review/index.html from a complete repository checkout.
2. For each of 5 mascots, play all 10 states in 256px and 64px view.
3. Look for jitter, inconsistent scale, missing limbs, abrupt cuts, silent frame holds and tiny unreadable details. Record any visible defect by character/state/frame.
4. Confirm loops are seamless; one-shot states (done and sad) stop gracefully instead of jumping to frame zero.
5. Check 64px overlay does not occlude important screen controls; Android permission opt-in and dismiss affordance are mandatory; iOS uses widgets/notifications instead.
6. Confirm muted audio by default, quiet hours and no surprise sounds from mere screen-time use.
7. Confirm reduced-motion setting: still pose with accessible text alternative and no forced autoplay.
8. Validate readability, light/dark contrast, and larger text sizes on actual Android hardware. iOS parity requires device testing and entitlement review.
9. Record test device model, OS version, battery impact over a repeatable 30-minute playback test, observed CPU/memory and any crash.
10. Sign off explicit PASS / FAIL per character/state with a review date, test evidence and corresponding GitHub Issue link.

## Approval gates
- G1 automated structural verification: PASS (see report).
- G2 full human art/animation review: PENDING.
- G3 responsive dark/light and accessibility review: PENDING.
- G4 Flutter runtime rendering, background/overlay battery measurement, Android and iOS platform limitations: NOT STARTED.

**Do not move asset acceptance issues to done before G2–G4 are evidenced.** No Flutter application production implementation should be implied by design previews.
