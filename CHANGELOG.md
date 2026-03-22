# Changelog

All notable changes to ZENiT are documented in this file.

## [1.3.2] - 2026-03-21

### Added
- Pro-locked home widget pipeline for Focus and Tasks with centralized bridge sync.
- Settings → Widgets management section with lock state, setup guidance, and manual refresh action.
- Entitlement reconciliation path on startup and app resume to tighten Pro state consistency.

### Changed
- Centralized Pro gate decisions for feature access checks and free-tier cap enforcement.
- Widget payload behavior now fails closed to locked state when entitlement or sync is unavailable.

### Fixed
- Prevented startup crash on unsupported `home_widget` platform channels by guarding `setAppGroupId` and handling plugin exceptions safely.

## [1.3.1] - 2026-03-20

### Added
- Initial in-app monetization foundation using Flutter `in_app_purchase`.
- New ZENiT Pro entitlement provider with local unlock persistence and purchase/restore stream handling.
- New Upgrade screen with localized store price loading, lifetime purchase CTA, and restore purchases action.

### Changed
- Added Settings → Monetization section with ZENiT Pro status and upgrade entry.
- Added dedicated `/upgrade` route for paywall navigation.
- Gated Focus Ambient View behind ZENiT Pro with direct upgrade CTA when locked.
- Added free-tier creation caps (5 habits, 10 active tasks) with provider-level enforcement.
- Added upgrade redirection and warning feedback when users hit free-tier creation limits.

### Platform
- Added Android billing permission (`com.android.vending.BILLING`) for Google Play purchases.

## [1.3.0] - 2026-03-14

### Added
- AMOLED-style Focus Ambient View with immersive full-screen presentation, drifted clock layout, and quick controls.
- Direct Ambient View launch from both the main Focus screen and Zen quick sheet.
- Silent Focus setting to suppress scheduled app reminders while a focus session is active.
- Reminder resync flow after focus suppression is lifted (tasks, habits, and journal prompt reminders).
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
- Fixed Ambient View black-screen issue by detecting background brightness and applying safe text colors (white on dark, black on light).
- Fixed Ambient View black-screen unexitable state by removing close button and ensuring back button navigation works seamlessly.
- Fixed navigator lock assertion error during Ambient View exit by deferring pop operations to post-frame callbacks and using mounted/route safety checks.
- Removed duplicate entry point for adding new notes (empty-state action removed; single FAB now standard).
- Consolidated Shopping List add flow from inline action to full-width FAB with bottom-sheet editor for consistency.
- Fixed Settings view to properly return to Dashboard on back press instead of exiting the app entirely.

### Polish
- Full-width standardized FAB across Notes, Shopping List, and all add-item flows (FloatingActionButtonLocation.centerFloat with screen-width SizedBox constraint).
- Added bottom padding (110px) to content grids and lists to prevent FAB occlusion of items.
- Improved Ambient View UX with "Tap to show controls" hint when controls auto-hide after 5 seconds.
- Simplified Ambient View exit affordance to back-button only (removed confusing close X button).
- Updated app version display to v1.3.2 (ZENiT) in Settings for public release labeling.
