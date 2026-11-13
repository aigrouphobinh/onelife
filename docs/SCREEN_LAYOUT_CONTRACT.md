# OneLife — SCREEN_LAYOUT_CONTRACT.md
Version 1.0 • Design-only gate • AI implementation contract

## Source of truth and precedence
1. docs/DESIGN_BRAIN.md — product, privacy and execution constraints.
2. docs/CHARACTER_ANIMATION_SPEC.md — mascot states and sprite semantics.
3. assets/characters/*/{manifest.json,master.svg} — actual asset inventory.
4. design/screens/*.svg and *.png — pixel layout reference for 390×844 logical demo canvas.
5. docs/UI_PAGE_SPEC.md — Flutter pages, controllers, device APIs.

**Do not code the UI until design review and device adaptation checklist is signed off.** PNG screens are illustrations, not screenshots of working Flutter code. All example tasks and metrics are mock data.

## Global layout/tokens
- Reference frame 390×844 logical pixels, SafeArea must supersede exact pixel coordinates on real phones.
- 24 px horizontal padding; 18 px card radius; 12–16 px vertical spacing; background #F8F6FD; primary #7759CB; ink #292448.
- 5 bottom tabs: Home, Tasks, Schedule, Habits, Assistant. Bottom bar preview begins at y=782; use SafeArea + NavigationBar, never absolute height on device.
- All interactive targets >=48 dp; text supports 200% scaling, screen readers and dark mode.
- No hardcoded demo dates/metrics in production; mock values serve composition only.
- Each page requires loading, empty, error and permission-denied variants.

## Page-to-Flutter map
| Design file | Route | Flutter page | Main regions (reference y) | Data fields / repositories | Platform bridges |
|---|---|---|---|---|---|
| 01-splash | /splash | SplashPage | wordmark, mascot center 170–450, tagline | PreferencesRepository.initialized, firstRun | WidgetsBinding, lifecycle |
| 02-onboarding | /onboarding | OnboardingPage | header 0–201, mascot 160–360, choice 390–591, CTA 625 | AssistantPreferences, onboardingDone, characterId | local DB; permissions requested contextually later |
| 03-home | /home | HomePage | hero 0–201, next due 205–309, task list 366–556, quick actions 614–737, bottom nav | TaskRepository.nextDue, TaskRepository.today, CharacterRepository.selectedCharacter | local clock/timezone, notifications state |
| 04-tasks | /tasks | TasksPage | header 0–125, filters 139–188, list 251–588, create CTA 656 | Task.id/title/dueAtUtc/priority/status | SQLite only |
| 05-schedule | /schedule | SchedulePage | header, alarm cards 174–351, events 416–629 | Alarm.id/localTime/recurrence/zone, Task.dueAt | local notifications, AlarmManager (Android) / UNUserNotificationCenter (iOS) |
| 06-habits | /habits | HabitsPage | header, usage card 141–316, pattern list 379–557, nudge toggle 591–699 | HabitDaily.dateLocal/minutes, consentVersion, bedtimeWindow | Android UsageStatsManager with Usage Access; iOS entitled Screen Time where available |
| 07-assistant | /assistant | AssistantPage | hero 0–201, mascot 130–310, greeting 344–414, suggestions 436–544, composer 578–634 | AssistantPreferences.aiProvider, UserIntent, LocalRuleEngine | on-device engine first; Gemini remote only after opt-in and payload review |
| 08-characters | /characters | CharactersPage | header, 5 mascot cards 198–541, animation selector 611–703 | CharacterAssetRepository.manifest, AssistantPreferences.characterId | sprite metadata & local preferences |
| 09-settings | /settings | SettingsPage | header, settings groups 143–660, bottom navigation | notificationEnabled, usageInsightsEnabled, overlayEnabled, aiConsent, exportRequest | settings intents; secure storage; permission APIs |
| 10-overlay-android | /overlay | OverlayPreview | mock Android launcher, draggable mini mascot near 230,577 | CharacterId, MascotState, nextReminder | Android overlay with explicit permission; iOS NOT supported cross-app |

## User actions and state ownership
- `onSaveNote` => NotesController.save => NoteRepository; local.
- `onCreateTask` => TaskController.create => TaskRepository; schedule local reminder only after permission.
- `onToggleAlarm` => ScheduleController.toggleAlarm => OS scheduling adapter with capability check, never false success.
- `onAcceptUsageAccess` => HabitController.requestUsagePermission => Android OS settings; iOS entitlement-based flow with unavailable fallback.
- `onSelectCharacter` => CharacterController.select(characterId) => preferences persistence, load clip from manifest.
- `onMascotEvent` => MascotStateMachine.apply(event) => expression key, priority, cooldown, reduced-motion fallback.
- `onEnableGemini` => AssistantController.showDisclosure => explicit consent; only approved fields may leave device.
- `onEnableOverlay` => OverlayController.requestPermission, never enabled implicitly; drag, dismiss, mute required.

## Acceptance gate for designers and AI engineers
- 10 SVG and 10 PNG files rendered and checksum manifest matches.
- Characters/animations from asset manifests, no placeholder SVG or static emoji substituted.
- All tab/CTA routes named and bounded by OS capability.
- Complete dark/light, error, permission refusal, reduced motion and large text layouts prior to product-quality signoff.
- No Flutter feature code changes until visual freeze is approved; existing Flutter prototype is not approved UI.

## Production sequence
A: Render and inspect 50 mascot clips → B: inspect 10 screen comps → C: adjust tokens/spacing & approve art direction → D: begin Flutter component implementation → E: accessibility, battery, overlay & iOS fallback device tests.
