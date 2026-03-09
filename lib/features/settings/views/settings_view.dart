import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/database_helper.dart';
import '../../../shared/utils/time_picker_helper.dart';
import '../../habit_tracker/providers/habit_provider.dart';
import '../../todo/providers/todo_provider.dart';
import '../../finance/providers/finance_provider.dart';
import '../../notes_shopping/providers/notes_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _refreshPermissionStatus();
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
                  const Divider(indent: 56),
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
                  const Divider(indent: 56),
                  _buildListTile(
                    context,
                    title: 'Default Reminder Time',
                    subtitle: _formatTimeForSettings(context, settings),
                    icon: Icons.schedule_outlined,
                    onTap: settings.journalPromptEnabled
                        ? () => _pickJournalReminderTime(context, ref, settings)
                        : null,
                  ),
                  const Divider(indent: 56),
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
            _buildSectionHeader(context, 'PRIVACY'),
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
                  const Divider(indent: 56),
                  _buildListTile(
                    context,
                    title: 'Delete All Data',
                    subtitle:
                        'Permanently erase tasks, habits, notes, journal, and finance logs.',
                    icon: Icons.delete_forever_outlined,
                    onTap: () => _confirmDeleteAllData(context, ref),
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
                    title: 'Theme Mode',
                    subtitle: 'Dark (Fixed)',
                    icon: Icons.dark_mode_outlined,
                  ),
                  const Divider(indent: 56),
                  _buildListTile(
                    context,
                    title: 'Version',
                    subtitle: 'v2.1.0 (ZENiT)',
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
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
          'This permanently erases all local data, including habits, tasks, finance logs, notes, shopping items, and journal entries.',
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
    ref.invalidate(habitListProvider);
    ref.invalidate(projectListProvider);
    ref.invalidate(taskListProvider);
    ref.invalidate(transactionListProvider);
    ref.invalidate(noteListProvider);
    ref.invalidate(shoppingListProvider);
    ref.invalidate(journalProvider);
    ref.invalidate(zenTimerProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All local data deleted.')));
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
}
