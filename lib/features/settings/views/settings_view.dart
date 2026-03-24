import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/providers/pro_access_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/widget_bridge_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/data_export_service.dart';
import '../../../core/utils/database_helper.dart';
import '../../../core/utils/provider_helpers.dart';
import '../../../shared/utils/time_picker_helper.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../shared/widgets/module_state_view.dart';
import '../../todo/models/task_model.dart';
import '../../todo/providers/todo_provider.dart';
import '../../zen_mode/providers/zen_mode_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  NotificationPermissionStatus _permissionStatus =
      NotificationPermissionStatus.unknown;
  bool _checkingPermission = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _refreshPermissionStatus();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = 'v${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _refreshPermissionStatus() async {
    setState(() => _checkingPermission = true);
    final status = await NotificationService.instance.getPermissionStatus();
    if (!mounted) return;
    setState(() {
      _permissionStatus = status;
      _checkingPermission = false;
    });
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    final status = await NotificationService.instance.requestPermissions();
    if (!mounted) return;

    setState(() => _permissionStatus = status);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification permission: ${_permissionLabel(status)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final settingsAsync = ref.watch(settingsProvider);
    final proState = ref.watch(proAccessProvider);

    return Scaffold(
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionHeader(context, 'PREFERENCES'),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildListTile(
                    context,
                    title: 'Currency Symbol',
                    subtitle: 'Current: ${settings.currency}',
                    icon: Icons.payments_outlined,
                    onTap: () =>
                        _showCurrencyPicker(context, ref, settings.currency),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'REMINDERS'),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Daily Journal Prompt'),
                    subtitle: const Text('Keep a nightly reflection cadence'),
                    value: settings.journalPromptEnabled,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setJournalPromptEnabled(value);
                    },
                  ),
                  dividerListTile,
                  _buildListTile(
                    context,
                    title: 'Notification Permission',
                    subtitle: _checkingPermission
                        ? 'Checking...'
                        : _permissionLabel(_permissionStatus),
                    icon: Icons.notifications_active_outlined,
                    onTap: () async {
                      if (_permissionStatus ==
                              NotificationPermissionStatus.denied ||
                          _permissionStatus ==
                              NotificationPermissionStatus.unknown) {
                        await _requestNotificationPermission(context);
                      } else {
                        await _refreshPermissionStatus();
                      }
                    },
                  ),
                  dividerListTile,
                  _buildListTile(
                    context,
                    title: 'Default Reminder Time',
                    subtitle: _formatTimeForSettings(context, settings),
                    icon: Icons.schedule_outlined,
                    onTap: settings.journalPromptEnabled
                        ? () => _pickJournalReminderTime(context, ref, settings)
                        : null,
                  ),
                  dividerListTile,
                  _buildListTile(
                    context,
                    title: 'Time Format',
                    subtitle: _timeFormatLabel(settings.reminderTimeFormat),
                    icon: Icons.access_time_filled_outlined,
                    onTap: () => _showTimeFormatPicker(
                      context,
                      ref,
                      settings.reminderTimeFormat,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'DATA'),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildListTile(
                    context,
                    title: 'Local-Only Storage',
                    subtitle: 'Data stays on this device unless you export it.',
                    icon: Icons.shield_outlined,
                  ),
                  dividerListTile,
                  _buildListTile(
                    context,
                    title: 'Export Data (JSON)',
                    subtitle: 'Save all your data to a JSON file.',
                    icon: Icons.download_outlined,
                    onTap: () => _exportDataJson(context, ref),
                  ),
                  dividerListTile,
                  _buildListTile(
                    context,
                    title: 'Import Data',
                    subtitle: 'Restore data from a JSON export file.',
                    icon: Icons.upload_outlined,
                    onTap: () => _importData(context, ref),
                  ),
                  dividerListTile,
                  _buildListTile(
                    context,
                    title: 'Delete All Data',
                    subtitle:
                        'Permanently erase tasks, habits, notes, shopping items, and journal entries.',
                    icon: Icons.delete_forever_outlined,
                    onTap: () => _confirmDeleteAllData(context, ref),
                  ),
                ],
              ),
            ),
            // Monetization section removed. Now handled as a separate Pro page.
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'WIDGETS'),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildListTile(
                    context,
                    title: 'Home Screen Widgets',
                    subtitle: _widgetStatusSubtitle(proState),
                    icon: Icons.widgets_outlined,
                    onTap: proState.hasValue && proState.value!
                        ? null
                        : () => context.push('/upgrade'),
                  ),
                  dividerListTile,
                  _buildListTile(
                    context,
                    title: 'Widget Setup',
                    subtitle:
                        'Long-press home screen → Widgets → ZENiT Focus or ZENiT Tasks',
                    icon: Icons.info_outline,
                  ),
                  dividerListTile,
                  _buildListTile(
                    context,
                    title: 'Refresh Widget Content',
                    subtitle: 'Re-publish current app state to widgets',
                    icon: Icons.sync_outlined,
                    onTap: () => _refreshWidgets(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'SYSTEM'),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildListTile(
                    context,
                    title: 'Version',
                    subtitle: _appVersion.isEmpty ? 'Loading...' : _appVersion,
                    icon: Icons.info_outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'ZENiT // PRIVATE BY DEFAULT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ),
        loading: () => const ModuleCardListSkeleton(
          itemCount: 5,
          horizontalPadding: 24,
          topPadding: 24,
          bottomPadding: 48,
        ),
        error: (_, __) => ModuleErrorState(
          title: 'Could not load settings',
          subtitle: 'Please try refreshing settings.',
          onRetry: () => ref.invalidate(settingsProvider),
        ),
      ),
    );
  }

  String _widgetStatusSubtitle(AsyncValue<bool> proState) {
    if (!proState.hasValue) {
      return 'Checking Pro entitlement...';
    }

    return proState.value!
        ? 'Unlocked. Focus and Tasks widgets can display live data.'
        : 'Locked in free plan. Upgrade to ZENiT Pro to unlock widgets.';
  }

  Future<void> _refreshWidgets(BuildContext context, WidgetRef ref) async {
    final focusState = ref.read(zenTimerProvider);
    final taskState = ref.read(allTaskListProvider);
    final tasks = taskState.hasValue ? taskState.value! : <Task>[];
    final canUseWidgets = ref
        .read(proAccessProvider.notifier)
        .ambientViewDecision()
        .allowed;

    await WidgetBridgeService.syncFromState(
      canUseWidgets: canUseWidgets,
      focusState: focusState,
      tasks: tasks,
    );

    if (!context.mounted) return;

    showSuccessSnackBar(context, 'Widget content refreshed.');
  }

  Future<void> _confirmDeleteAllData(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DELETE ALL DATA?'),
        content: const Text(
          'This permanently erases all local data, including habits, tasks, notes, shopping items, and journal entries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (approved != true || !context.mounted) {
      return;
    }

    await DatabaseHelper().deleteAllData();
    await NotificationService.instance.cancelAll();
    await ref.read(settingsProvider.notifier).resetToDefaults();

    // Force module providers to reload after wipe.
    invalidateAllProviders(ref);

    if (context.mounted) {
      showSuccessSnackBar(context, 'All local data deleted.');
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      onTap: onTap,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, size: 20)
          : null,
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: bottomSheetShape,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHOOSE CURRENCY',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [r'$', '€', '£', '¥', '₹'].map((c) {
                final isSelected = c == current;
                return ChoiceChip(
                  label: Text(c),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(settingsProvider.notifier).setCurrency(c);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickJournalReminderTime(
    BuildContext context,
    WidgetRef ref,
    UserSettings settings,
  ) async {
    final selected = await showZenitTimePicker(
      context: context,
      initialTime: settings.journalReminderTime,
    );

    if (selected == null) return;

    await ref.read(settingsProvider.notifier).setJournalReminderTime(selected);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal reminder time updated.')),
    );
  }

  void _showTimeFormatPicker(
    BuildContext context,
    WidgetRef ref,
    ReminderTimeFormat current,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: bottomSheetShape,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.phone_android_outlined),
                title: const Text('SYSTEM DEFAULT'),
                subtitle: const Text('Follow device 12h/24h preference'),
                trailing: current == ReminderTimeFormat.system
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setReminderTimeFormat(ReminderTimeFormat.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timelapse_outlined),
                title: const Text('12-HOUR'),
                subtitle: const Text('Example: 9:00 PM'),
                trailing: current == ReminderTimeFormat.h12
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setReminderTimeFormat(ReminderTimeFormat.h12);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.looks_two_outlined),
                title: const Text('24-HOUR'),
                subtitle: const Text('Example: 21:00'),
                trailing: current == ReminderTimeFormat.h24
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .setReminderTimeFormat(ReminderTimeFormat.h24);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _permissionLabel(NotificationPermissionStatus status) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return 'Granted';
      case NotificationPermissionStatus.denied:
        return 'Denied (tap to request)';
      case NotificationPermissionStatus.unsupported:
        return 'Not supported on this platform';
      case NotificationPermissionStatus.unknown:
        return 'Unknown (tap to refresh)';
    }
  }

  String _timeFormatLabel(ReminderTimeFormat format) {
    switch (format) {
      case ReminderTimeFormat.system:
        return 'System Default';
      case ReminderTimeFormat.h12:
        return '12-hour';
      case ReminderTimeFormat.h24:
        return '24-hour';
    }
  }

  String _formatTimeForSettings(BuildContext context, UserSettings settings) {
    final localizations = MaterialLocalizations.of(context);

    return localizations.formatTimeOfDay(
      settings.journalReminderTime,
      alwaysUse24HourFormat: _use24HourFormat(
        context,
        settings.reminderTimeFormat,
      ),
    );
  }

  bool _use24HourFormat(BuildContext context, ReminderTimeFormat format) {
    switch (format) {
      case ReminderTimeFormat.system:
        return MediaQuery.of(context).alwaysUse24HourFormat;
      case ReminderTimeFormat.h12:
        return false;
      case ReminderTimeFormat.h24:
        return true;
    }
  }

  Future<void> _exportDataJson(BuildContext context, WidgetRef ref) async {
    // Let user pick a directory
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      if (context.mounted) {
        showWarningSnackBar(
          context,
          'Export cancelled. No directory selected.',
        );
      }
      return;
    }

    final exportService = DataExportService();
    final settingsMap = await ref
        .read(settingsProvider.notifier)
        .exportBackupMap();

    if (!context.mounted) return;

    try {
      final filePath = await withLoadingDialog(
        context,
        () => exportService.exportToJson(
          settings: settingsMap,
          customDirectoryPath: selectedDirectory,
        ),
      );

      if (filePath != null) {
        if (context.mounted) {
          _showExportResultDialog(context, filePath, 'JSON');
        }
      } else {
        if (context.mounted) {
          showErrorSnackBar(context, 'Export failed. Please try again.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Export error: $e');
      }
    }
  }

  void _showExportResultDialog(
    BuildContext context,
    String path,
    String format,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your data has been exported to $format format.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text('Location:', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                path,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You can find this file in your device\'s Documents folder.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    // Confirm user intent before starting restore flow.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WARNING: This will replace all current data with the imported data.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap IMPORT to choose a JSON backup file from your device.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('IMPORT'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final filePath = await _pickJsonBackupFile();
    if (!context.mounted) return;
    if (filePath == null || filePath.isEmpty) {
      showWarningSnackBar(
        context,
        'Import cancelled. No backup file selected.',
      );
      return;
    }

    if (!context.mounted) return;

    try {
      final exportService = DataExportService();
      final result = await withLoadingDialog(
        context,
        () => exportService.importFromJsonDetailed(filePath),
      );

      if (result != null && result.success) {
        if (result.settings != null) {
          await ref
              .read(settingsProvider.notifier)
              .applyBackupMap(result.settings!);
          if (!context.mounted) return;
        }

        // Force all providers to reload
        invalidateAllProviders(ref);

        if (context.mounted) {
          showSuccessSnackBar(context, result.message);
        }
      } else {
        if (context.mounted) {
          showErrorSnackBar(context, result?.message ?? 'Import failed.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Import error: $e');
      }
    }
  }

  Future<String?> _pickJsonBackupFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
    );

    if (picked == null || picked.files.isEmpty) {
      return null;
    }

    return picked.files.single.path;
  }
}
