# Test Strategy

## Unit
Note/task validation, repository operations, Unicode search, date/time conversions, reminders and permission state.

## Widget
Capture form, empty state, search, task completion, accessibility semantics, large text.

## Integration
Offline startup; restart persistence; migrations; import/export; notification permission denied; app background/foreground.

## Device matrix
Android low-end and mid-range; current Android and one older supported version; iPhone small/large screen before iOS release.

## Non-functional
Startup latency, memory use, battery, crash-free sessions, keyboard navigation, screen readers, privacy and security checks.

## CI gate
flutter format --set-exit-if-changed . ; flutter analyze ; flutter test.
