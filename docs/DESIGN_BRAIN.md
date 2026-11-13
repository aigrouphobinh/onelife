# OneLife — Design Brain / AI Build Contract v1.0

> **DESIGN FREEZE: ASSETS FIRST.** No feature implementation before the character pack, icons, motion specification, and page layouts are approved. This file is the source of truth for future AI agents. Existing Flutter code is a prototype only; do not treat it as an approved UI.

## 0. Product decisions
- A friendly animated miniature brain assistant, optionally floating above other apps on Android with explicit overlay permission. iOS uses in-app mascot, widgets and notifications; no unrestricted overlay.
- Core functions: alarms, tasks, reminders, gentle screen-time prompts, personalized routines. No surveillance or silent access to other apps.
- All personal records and habit profiles stored locally by default; user-controlled export/delete. No forced account or cloud service.
- Optional Gemini: explicitly enabled and consented, remote processing disclosed. Offline local model/rule engine is the default; do not promise Gemini is local or always free.
- Multiple selectable mascot characters, all with distinct state animations.
- Vietnamese-first, Material 3, dark/light mode, accessible reduced-motion option.

## 1. AI agent execution rules
1. Read this file and linked docs before work. Never skip design/asset gates.
2. Every task must have input assets, output path, validation checklist and evidence.
3. No fake animation, placeholder art in a completed screen, or falsely claimed device capability.
4. Commit assets and their license metadata first; implement rendering only after visual QA.
5. Each feature requires Android/iOS feasibility check and permission-denied fallback.
6. Keep user data local; any outbound payload requires explicit UI consent and audit.
7. Do not mark an issue complete without actual build/test artifacts.

## 2. Pages and reusable regions
| Route / Page | Regions and widgets | State/Controller | Device data / API | Acceptance |
| --- | --- | --- | --- | --- |
| /splash Splash | logo, mascot intro, loading | AppStartupState | local settings, app lifecycle | fast, skip animations on reduced motion |
| /onboarding | permission explanation, mascot picker, privacy controls | OnboardingController | SharedPreferences/local DB, OS permissions only when needed | no forced permissions |
| /home | greeting, mascot, today summary, quick actions, focus prompt | HomeController | local TaskRepository, AlarmRepository, HabitRepository, clock | offline, clear empty state |
| /tasks | filter tabs, task list, create/edit sheet, completion | TaskController | SQLite task table | CRUD, validation, persistence |
| /schedule | day/week list, alarms, recurrence, snooze | ScheduleController | local DB, flutter_local_notifications, timezone; Android exact alarms only when eligible | test DST/reboot/permission denial |
| /habits | daily screen-time charts, opt-in patterns, limits | HabitController | Android UsageStatsManager with user-granted Usage Access; iOS FamilyControls/DeviceActivity only if entitled and authorized | no hidden monitoring; explain unavailable data |
| /assistant | mascot stage, suggestions, text input, consent to Gemini | AssistantController | on-device rules/model; optional Gemini remote API | offline fallback; never transmit raw history by default |
| /characters | mascot catalog, preview, expression gallery | CharacterController | bundled asset manifest, local selection | all states previewable |
| /settings | character, voice, reminders, permissions, AI, privacy, export | SettingsController | local preferences, OS settings deep-links, secure storage | revoke permissions and delete data |
| /overlay | compact floating mascot, quick reminder action | OverlayController | Android SYSTEM_ALERT_WINDOW after opt-in; not supported as unrestricted iOS overlay | drag, dismiss, battery budget, no touch obstruction |

## 3. Component map
MascotStage: characterId, expression, playbackMode, scale, onTap; NotificationCard: eventId, title, dueAt, action; TaskTile: taskId, status, priority; AlarmTile: alarmId, time, repeatDays, enabled; UsageInsightCard: minutesToday, baselineMinutes, confidence, consentState; PrivacyPermissionRow: permission, granted, rationale, openSettings.

## 4. State machine and triggers
MascotState = idle | happy | remind | alarm | focus | study | sleepy | done | thinking | sad.
Priority: alarm > remind > done > focus > study > sleepy > happy > thinking > idle. 'sad' is never used to guilt or shame a user.
Event sources: task_due, alarm_fired, task_completed, user_opened_app, user_started_focus, focus_finished, screen_time_threshold_reached, user_tapped_mascot, bedtime_window.
Cooldown: screen-time nudges max once per 2 hours, max 2/day, opt-in; quiet hours suppress all non-critical mascot nudges; user may mute entirely.

## 5. Local data contracts (Dart names)
UserProfile(id, locale, timezone, createdAt); AssistantPreferences(characterId, animationEnabled, reducedMotion, overlayEnabled, usageInsightsEnabled, aiProvider, bedtimeStart, bedtimeEnd); Task(id, title, description, dueAtUtc, completedAtUtc, priority, recurrenceRule); Alarm(id, localTime, timezone, repeatDays, enabled, snoozeMinutes); HabitDaily(dateLocal, screenMinutes, source, consentVersion); MascotEvent(id, characterId, state, source, occurredAtUtc); NotificationLog(id, eventId, deliveredAtUtc, action); AIConsent(provider, enabled, allowedDataCategories, updatedAtUtc).
Use repository interfaces; version schema migrations; UTC timestamps for events, explicit timezone for alarms.

## 6. API feasibility
Android: UsageStatsManager requires user to grant Usage Access in system settings; overlay requires SYSTEM_ALERT_WINDOW and may be restricted; exact alarm APIs are permission/policy constrained; WorkManager for deferrable background tasks; local notifications via plugin. Do not infer precise per-app behavior without access.
iOS: no unrestricted cross-app overlay; Screen Time frameworks require entitlements/authorization; notifications via UNUserNotificationCenter; WidgetKit/Live Activities have OS limits; exact alarm-like behavior differs. Provide feature-parity alternatives rather than false claims.

## 7. Acceptance gates
G0 design docs, page wireframes, tokens, interaction flow approved.
G1 character source assets, expressions, animation sheets and manifest complete with license metadata.
G2 icons, sounds, responsive page designs, dark/light and accessibility variants complete.
G3 Flutter architecture and rendering implementation only after G0–G2.
G4 real-device QA: animation frame consistency, CPU/memory/battery, permission denial, notification delivery, accessibility.

## 8. Linked specs
[Character animation and asset pipeline](CHARACTER_ANIMATION_SPEC.md); [UI page regions](UI_PAGE_SPEC.md); [existing product requirements](PRD.md).

## 9. Current design artifact execution map (2026-11-14)
- Characters: 5 canonical master SVGs in assets/characters/<id>/master.svg.
- Animation: 50 per-state SVG sheets, 500 frames, matching PNG atlas, GIF preview, metadata and character manifest. Actual PNG/GIF files generated by GitHub Actions and stored on main.
- Icon set: 12 independent original SVG icons in assets/icons.
- UI comps: 10 mobile pages in design/screens/*.svg and *.png, 390×844 concept canvas only.
- Page/field/Flutter mapping: docs/SCREEN_LAYOUT_CONTRACT.md.
- QA and rights: docs/ASSET_QA.md and docs/ASSET_REGISTER.md.
- **NO Flutter feature implementation yet under this asset-first gate.** Existing prototype code is not approval of UI. Next gate is visual acceptance and device motion QA.
