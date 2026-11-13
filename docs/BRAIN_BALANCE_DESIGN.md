# OneLife — Brain Balance (Digital Wellbeing) Feature Contract v1.0

**Status:** visual/design work first; native usage telemetry, persistence and Flutter user interface are **not implemented**.

## 1. Product intent and evidence boundary

Brain Balance is an **opt-in, privacy-first reflection feature**, helping a person notice prolonged or unwanted phone use, take breaks, and feel supported. The mascot's color/face/state is playful metaphor, not a biomarker, clinical assessment, neuronal injury or evidence of permanent damage. Avoid labels such as "brain damaged", "brain health 30%", "dead neurons", addiction diagnoses, guilt, shaming or fear marketing. Time alone cannot measure injury. The American Academy of Pediatrics notes no universal safe-use-hours limit applicable to everyone; focus on quality, context and personal goals.

- AAP: https://www.aap.org/en/patient-care/media-and-children/center-of-excellence-on-social-media-and-youth-mental-health/qa-portal/qa-portal-library/qa-portal-library-questions/screen-time-guidelines/
- Android: https://developer.android.com/reference/android/app/usage/UsageStatsManager
- Apple: https://developer.apple.com/documentation/screentimeapidocumentation
- Apple Family Controls: https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement

## 2. Animation keys and visuals (5 clips per character)

| UI level | State key | Mascot motion | User copy | When shown |
|---|---|---|---|---|
| Steady | `balanced` | Gentle bouncy motion, small mint sparkles and bright eyes | "Bạn đang cân bằng theo mục tiêu đã chọn" | Recent use below personal goal; or after a completed pause |
| Needs a break | `strained` | Slower blinking, forehead sweat and shoulders lower | "Bạn muốn nghỉ mắt một chút không?" | Reaching personal break reminder, with explicit tracking consent |
| Over target | `overloaded` | Comic-purple stress scribbles + wobble, strained eyes and small pulses | "Đã vượt mục tiêu bạn đặt. Nghỉ khi phù hợp nhé." | Exceeded personal continuous-use goal; not a medical indicator |
| On break | `resting` | Eyes closed, slow inhale/exhale, soft blue calm waves | "Giờ nghỉ của bạn đang diễn ra" | User explicitly starts a break timer |
| Back to balance | `recovering` | Gradual bright color, drifting stars and gentle celebratory stretch | "Bạn đã dành thời gian nghỉ. Tiếp tục theo nhịp của mình nhé." | User ends chosen break; **never** promise neurological repair |

Characters: brain, cat, dog, robot, sprout. All have the same state keys, with character-specific facial expressions and body cues. The Brain's purple streaks/cracks (if present) are decorative *comic stress lines*, not tissue damage.

### Output asset contract
`assets/characters/<characterId>/<state>/sheet.svg` → generated `sheet.png`, `preview.gif`, `metadata.json`. Each clip is a transparent RGBA atlas with 4 columns, 256×256 cells; original source and resulting assets tracked in the GitHub asset register. Playback from PNG metadata only; see `ANIMATION_RUNTIME_CONTRACT.md`.

## 3. Product and native data flow

```text
User opts in → permission/status check → supported, local usage sample
    → local time-window aggregation → transparent personal goals/rules
    → proposed mascot state → cooldown/quiet-hour filter → optional nudge
    → user's action (start break / snooze / disable) → local storage
```

- Android: `UsageStatsManager.queryUsageStats` / `queryEvents` after user grants Usage Access through `Settings.ACTION_USAGE_ACCESS_SETTINGS`. Aggregates may be coarse and inaccurate for continuous-session inference; handle locked-device nulls, missing permission and timezone splits. Do not capture app contents or notifications.
- iOS: `DeviceActivity`, `FamilyControls`, `ManagedSettings` only where entitled/authorized; provide manual focus/break sessions and in-app tracking fallback when unavailable. Not an unrestricted system-usage feed.
- Flutter interfaces proposed (future code): `UsageObservationService`, `UsagePermissionService`, `BreakTimerRepository`, `WellbeingPreferencesRepository`, `BrainBalanceRulesEngine`, `MascotStateMachine`, `WellbeingNudgeService`.
- Local data: `DailyUsageSummary(dateLocal, totalMinutes, source, permissionVersion)`, `BreakSession(id, startedAtUtc, endedAtUtc, status)`, `WellbeingGoals(activeUseLimitMinutes, breakDurationMinutes, quietHours, workModeExclusion, insightsOptIn)`, `WellbeingStateSnapshot(level, reasonCode, inputWindow, timestampUtc)`. Defaults are `unknown` until consent and an actual sample exist.
- No upload of app usage/history, app package lists, detected routines, or scores to cloud. Optional Gemini must not receive this data without a separate explicit scoped consent and preview.
- Offline-first: deterministic rules engine is enough for MVP; no cloud AI and no LLM required.

## 4. Rules engine (user-editable, non-medical)

- Default **disabled** until explanation and consent; never infer hidden phone habits without permission.
- Personal goal rather than prescribed health cutoff. During onboarding, let user set `breakReminderAfterMinutes` and `dailyReflectionGoalMinutes` (optional), or leave all unset and show `unknown`.
- Example only (not medical thresholds): at `>=0.8 * breakReminderAfterMinutes` → `strained`; at `>=1.0 * breakReminderAfterMinutes` → `overloaded`. Never label health from thresholds.
- `resting` overrides the passive state when a user starts a break. `recovering` follows completion for a brief one-shot animation; then `balanced` or normal `idle`. Do not claim rest biologically heals brain damage.
- During opt-in Work/Study mode, no intrusive nudge; still allow deliberate reminder. Suppress nudges during quiet hours or while in Do Not Disturb when OS permits.
- Never send more than 2 automatic nudge notifications per 24 hours; minimum 2h between; no repeat when dismissed or when user declines. User can snooze, mute, disable or purge history at any time.
- If information is missing, stale or permission denied, show `unknown` with explanation; **do not fabricate usage history or score**.
- Preserve the higher-priority `alarm` / `remind` mascot expressions. Wellness cues have lower priority and should never interrupt critical work.
- Personalization is local and explainable: compare to the user's explicitly chosen goals, not opaque "AI health" scores; optional recommendations can be accepted/rejected without changing default settings.

## 5. Regions in each page and call signatures

| Page | Region | Widgets / callbacks | Real inputs |
|---|---|---|---|
| `/home` | Mascot + "Nhịp dùng điện thoại" chip | `BrainBalanceBadge(level, reason)`, `onTapOpenHabits()` | `BrainBalanceRulesEngine.evaluate()` from local source |
| `/habits` | Screen time detail | `UsageSummaryCard`, `BrainBalanceStage`, `BreakNowButton`, `WellbeingGoalEditor`, `DataSourceLabel` | `DailyUsageSummary`, `WellbeingGoals`, actual permission state |
| `/settings` | Digital wellbeing options | `UsagePermissionRow`, `breakMinutesSlider`, `nudgeEnabledToggle`, `deleteUsageData()` | Local preferences and OS settings |
| `/characters` | New wellbeing preview tab | `CharacterClipPreview(category: wellbeing)`, `onChangeState()` | `manifest.json` from character bundle |
| `/overlay` | Optional, never forced | `MascotStage`, `onDismiss()`, `onPauseNudges()` | Android granted overlay permission; no iOS cross-app overlay |

Use no permanently visible status card when the person declines tracking. `unknown` is neutral, not greyed-out "damaged".

## 6. Test plan and exit gate

### Automated
- Asset generation: `sheet.png` and GIF + metadata for each chosen wellbeing state; at least 75% changing adjacent poses, no clipping, 256-cell/4-column atlas and verified SHA.
- Unit rules: missing consent; permission revoked; no goals; changing user-defined goals; midnight and timezone; foreground gap/unknown sample; break start/cancel/finish; priority override; cooldown and quiet hours; work/study pause.
- Privacy: no default background monitoring, no outbound telemetry, local purge works, all OS permissions explicitly requested and revocable.

### Human / device (still pending)
- 64px/96px/144px visible emotional progression in light/dark themes; no fear-based wording or severe injury imagery.
- No mascot jitter or flashing/strobing; reduced-motion still pose; VoiceOver/TalkBack meaning readable as text.
- Battery/CPU on low-end Android, no excessive polling and no overlay obstructing controls.
- iOS unsupported/entitlement-denied experience; no misleading claims.

## 7. Production sequence

**B0:** Create 25 wellbeing vector clips and their metadata, preview/contact sheets, update asset register.  
**B1:** Visual QA for emotional continuity and overlay readability.  
**B2:** Build UI design source for habits and onboarding consent, dark/light.  
**B3:** Only after design approval, implement local use-data adapter, goals/rules and UI in Flutter and native bridges.  
**B4:** Test on real devices and release gradually.

**Do not call the feature complete until B3–B4 are proven.**