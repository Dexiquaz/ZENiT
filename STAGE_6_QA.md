# Stage 6 QA & Release Prep (without iOS Widget Extension)

Date: 2026-03-21
Scope: Monetization hardening + Pro-locked widgets on Android and shared Dart logic.
Out of scope: Native iOS Widget Extension implementation.

## Execution Log

- 2026-03-21: ✅ `flutter analyze` passed (`No issues found`).
- 2026-03-21: ✅ `test/widget_test.dart` passed.
- 2026-03-21: ⚠️ `flutter run` runtime smoke was not executed in-agent (interactive run skipped), so runtime/device checks remain manual.

## Automated Validation

- ✅ `flutter analyze` passed (`No issues found`).
- ✅ `test/widget_test.dart` passed.

## Implemented Coverage Checklist

### Pro entitlement and gate behavior

- ✅ Pro entitlement provider is centralized and used for gate decisions.
- ✅ Ambient view access checks use fail-closed entitlement decisions.
- ✅ Habit creation cap enforced at provider layer for free tier.
- ✅ Task creation cap enforced at provider layer for free tier.
- ✅ Entitlement reconciliation runs on startup and app resume.

### Widget lock/unlock behavior

- ✅ Widget bridge writes locked payload for non-Pro users.
- ✅ Widget bridge writes unlocked payload for Pro users using live Focus/Tasks state.
- ✅ Widget route payload points to `/upgrade` while locked.
- ✅ Widget route payload points to feature routes while unlocked.
- ✅ Widget sync is subscribed to focus/task/pro state updates.
- ✅ Sync fallback is fail-closed to locked payload if an exception occurs.

### Platform stability

- ✅ Home widget initialization avoids unsupported platform-channel crash:
  - `setAppGroupId` called only on iOS.
  - `MissingPluginException` and `PlatformException` handled safely.

## Manual QA Scenarios (to execute on device)

### Purchase and restore

1. Launch app as free user.
2. Open Settings → ZENiT Pro and start purchase flow.
3. Confirm entitlement flips to Pro and gates unlock.
4. Reinstall app and trigger restore.
5. Confirm entitlement restores and widgets unlock.

### Free-tier limits

1. Stay on free plan.
2. Create habits until limit is reached; verify block + upgrade CTA.
3. Create active tasks until limit is reached; verify block + upgrade CTA.

### Widget behavior

1. Add Focus and Tasks widgets to Android home screen.
2. On free plan, verify locked messaging appears.
3. Upgrade to Pro and verify widgets switch to live content.
4. Toggle app foreground/background and verify resume sync keeps content current.

### Failure-path behavior

1. Simulate temporary entitlement/store unavailability.
2. Verify app remains stable and widget content remains locked/fail-closed.

## Manual QA Result Matrix

Use this to record final pass/fail during device validation.

| Area | Scenario | Expected | Result |
|---|---|---|---|
| Purchase | Free → Buy Pro | Entitlement becomes Pro, gated features unlock | ⬜ Pending |
| Restore | Reinstall + Restore | Pro entitlement restored and persisted | ⬜ Pending |
| Habit cap | Create 6th habit on free | Blocked with upgrade CTA | ⬜ Pending |
| Task cap | Create 11th active task on free | Blocked with upgrade CTA | ⬜ Pending |
| Widget locked | Free user widgets | Locked text + route to `/upgrade` | ⬜ Pending |
| Widget unlocked | Pro user widgets | Live focus/tasks payload + feature routes | ⬜ Pending |
| Lifecycle sync | Resume app from background | Widget content refreshes without errors | ⬜ Pending |
| Fail-closed | Entitlement/sync exception | App stable, widgets stay locked fallback | ⬜ Pending |

## Release Notes Summary

- Monetization is now enforced by centralized Pro gate logic with provider-level limits.
- Android home widgets are available as a Pro feature with lock-state fallback.
- Lifecycle reconciliation and fail-closed widget syncing reduce bypass and state-drift risk.
