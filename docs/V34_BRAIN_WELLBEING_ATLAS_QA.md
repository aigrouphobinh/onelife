# OneLife V3.4 — Brain wellbeing atlas integration

## Source-of-truth audit (2026-11-15)

Repository `assets/characters-v2/brain/` already contains 15 state
folders, including five relevant to digital wellbeing.

The native Brain overlay now plays the **actual existing** transparent PNG
atlases, not newly invented art or a tinted Idle substitute.

| Priority | State | Frames | Grid | Frame duration | Art status |
|---|---|---:|---|---:|---|
| Normal fallback | idle | 8 | 4×2 | 140 ms | Candidate, visual review pending |
| While 25m Focus runs | focus | 8 | 4×2 | 160 ms | Derived pose composite; review pending |
| Below user-defined daily goal × 0.8 | balanced | 8 | 4×2 | 140 ms | Derived pose composite; review pending |
| 80%–99% of user-defined daily goal | strained | 10 | 4×3 | 160 ms | Derived pose composite; review pending |
| At/above user's daily goal | overloaded | 12 | 4×3 | 115 ms | Illustrated V2 candidate; review pending |

The product's `manifest.json` explicitly declares
`productionReady=false`. This remains unchanged. Art source/provenance
and licensing are recorded in `docs/ASSET_REGISTER.md` and per-state
metadata.

## Permission and personal goal

- Device Usage Access requires user confirmation in Android Settings.
- Permission by itself never assigns a wellbeing goal. A goal remains
  **unset** by default even when usage statistics are available.
- The user may select 60, 120, 180, 240 or 360 minutes in
  **Trợ lý nổi Android → Xem dữ liệu sử dụng thực tế**, or disable the goal.
- The native service allows 30–720 minutes, stored locally via Android
  SharedPreferences. No app name or raw UsageEvents are stored.
- Without permission, reliable event evidence, or a user-chosen goal,
  Brain is neutral Idle (unless an actual Focus session is running).
- When a user edits a goal with Brain running, Android requests an immediate
  **refresh of the existing service**, never starts a new overlay.
- This is a **daily reflection goal**, not a *continuous phone session*
  detector, medical risk threshold, or neurological diagnosis.
- Only a small local, explanatory mascot reaction is delivered. No
  intrusive notifications, forced app restriction or automatic blocking.

## Runtime guarantees

- `BrainOverlayService.SpriteView` crops each source frame by the actual
  column/row and frame count, and advances with each state's own interval.
- Focus animation preempts passive wellbeing states. On ending Focus, it
  resolves the currently observed goal state.
- Only Idle, Focus and at most one wellbeing atlas are decoded at once,
  keeping atlas memory limited. If a candidate file is missing, it falls
  back to Idle/master without faking a successful new animation.
- Android's animator-scale=0 preference suppresses sprite motion; screen-off
  and battery saver reduce animation refreshes.
- In-app state labels and native overlay captions say measurements are
  approximate; they never label medical brain injury or pathology.
- Visual QA on real Android at 64/96/144px, varied OEMs, light/dark,
  TalkBack and reduced motion is **pending**.

## CI acceptance

1. `tools/test_brain_native_clip_contract.py` validates PNG IHDR
   dimensions, metadata counts, timing, declared bundled Flutter assets,
   Focus priority and candidate-art status.
2. `tools/test_usage_insights_contract.py` validates consent, no automatic
   goal, and no per-app data export.
3. Flutter widget tests validate goal selection/removal and truthful
   unknown-without-goal state.
4. Android APK is built with the original Idle, Focus, Balanced, Strained,
   Overloaded sheets and checked with `unzip`.

**Art completion status:** Integration of five already existing clips is a
runtime milestone; it does NOT equal approval of 15 distinct original
frame-by-frame animations. The deliberate `resting`/`recovering` break state machine has since been
added as a separate implementation milestone. Its deadline persistence and
12-frame one-shot animation are documented in
[V34_BRAIN_REST_RECOVERY_QA.md](V34_BRAIN_REST_RECOVERY_QA.md); physical
device art/interaction QA remains pending.
