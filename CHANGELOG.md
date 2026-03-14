# Changelog

All notable changes to ZENiT are documented in this file.

## [1.3.0] - 2026-03-14

### Added
- AMOLED-style Focus Ambient View with immersive full-screen presentation, drifted clock layout, and quick controls.
- Direct Ambient View launch from both the main Focus screen and Zen quick sheet.
- Silent Focus setting to suppress scheduled app reminders while a focus session is active.
- Reminder resync flow after focus suppression is lifted (tasks, habits, bills, and journal prompt reminders).
- Shared module state components for consistent empty, loading, and error UI patterns.
- Inline state components for compact in-card async feedback (loader and error with optional retry).
- Task-level focus stats surfaced in both Tasks and Focus (today minutes and weekly cycles).

### Changed
- Standardized module-level async states across key modules to use shared state widgets.
- Updated Focus screen linked-task, session history, and preference surfaces to use consistent loading and retry behavior.
- Updated Zen quick sheet task-state handling with compact inline loading/error and retry.
- Updated task editor category async feedback to use inline shared states instead of ad-hoc widgets.
- Improved dashboard module state copy consistency for loading and error summaries.
- Added wakelock_plus dependency to keep the screen awake during ambient focus sessions.

### Fixed
- Resolved inconsistent in-card async messaging for focus stats and task/category selectors.
- Prevented reminder noise during active focus sessions when Silent Focus is enabled.
- Ensured suppressed reminders are restored through explicit provider resync once suppression ends.
- Closed remaining UI consistency gaps in empty/loading/error state handling across modules.
