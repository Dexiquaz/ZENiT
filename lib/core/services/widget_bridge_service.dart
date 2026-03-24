import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/todo/models/task_model.dart';
import '../../features/zen_mode/providers/zen_mode_provider.dart';

class WidgetBridgeService {
  static const _appGroupId = 'group.com.zenit.app';

  static const _focusWidgetName = 'ZenitFocusWidgetProvider';
  static const _tasksWidgetName = 'ZenitTasksWidgetProvider';

  static const _focusTitleKey = 'focus_widget_title';
  static const _focusBodyKey = 'focus_widget_body';
  static const _tasksTitleKey = 'tasks_widget_title';
  static const _tasksBodyKey = 'tasks_widget_body';
  static const _focusRouteKey = 'focus_widget_route';
  static const _tasksRouteKey = 'tasks_widget_route';

  static const _upgradeRoute = '/upgrade';
  static const _focusRoute = '/focus';
  static const _tasksRoute = '/tasks';

  static Future<void> initialize() async {
    if (!_supportsWidgets) {
      return;
    }

    if (Platform.isIOS) {
      try {
        await HomeWidget.setAppGroupId(_appGroupId);
      } on MissingPluginException {
        return;
      } on PlatformException {
        return;
      }
    }
  }

  static bool get _supportsWidgets => Platform.isAndroid || Platform.isIOS;

  static Future<void> syncFromState({
    required bool canUseWidgets,
    required ZenTimerState focusState,
    required List<Task> tasks,
  }) async {
    if (!_supportsWidgets) {
      return;
    }

    try {
      if (!canUseWidgets) {
        await _writeLockedPayload();
        await _refreshWidgets();
        return;
      }

      await _writeUnlockedPayload(focusState: focusState, tasks: tasks);
      await _refreshWidgets();
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static Future<void> syncLockedState({required bool canUseWidgets}) async {
    if (canUseWidgets) {
      return;
    }

    if (!_supportsWidgets) {
      return;
    }

    try {
      await _writeLockedPayload();
      await _refreshWidgets();
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  static Future<void> _writeLockedPayload() async {
    await HomeWidget.saveWidgetData<String>(_focusTitleKey, 'ZENiT Focus');
    await HomeWidget.saveWidgetData<String>(
      _focusBodyKey,
      'Widget locked. Upgrade to ZENiT Pro.',
    );
    await HomeWidget.saveWidgetData<String>(_focusRouteKey, _upgradeRoute);

    await HomeWidget.saveWidgetData<String>(_tasksTitleKey, 'ZENiT Tasks');
    await HomeWidget.saveWidgetData<String>(
      _tasksBodyKey,
      'Widget locked. Upgrade to ZENiT Pro.',
    );
    await HomeWidget.saveWidgetData<String>(_tasksRouteKey, _upgradeRoute);
  }

  static Future<void> _writeUnlockedPayload({
    required ZenTimerState focusState,
    required List<Task> tasks,
  }) async {
    final pendingTasks = tasks.where((task) => !task.completed).toList();
    final topTasks = pendingTasks.take(3).map((task) => task.title).toList();

    final focusBody = focusState.isRunning
        ? '${focusState.phaseLabel} • ${focusState.timeLabel}'
        : 'Ready • ${focusState.timeLabel}';

    final tasksBody = topTasks.isEmpty
        ? 'No pending tasks'
        : topTasks.join(' • ');

    await HomeWidget.saveWidgetData<String>(
      _focusTitleKey,
      'ZENiT ${focusState.phaseLabel}',
    );
    await HomeWidget.saveWidgetData<String>(_focusBodyKey, focusBody);
    await HomeWidget.saveWidgetData<String>(_focusRouteKey, _focusRoute);

    await HomeWidget.saveWidgetData<String>(_tasksTitleKey, 'ZENiT Tasks');
    await HomeWidget.saveWidgetData<String>(_tasksBodyKey, tasksBody);
    await HomeWidget.saveWidgetData<String>(_tasksRouteKey, _tasksRoute);
  }

  static Future<void> _refreshWidgets() async {
    await HomeWidget.updateWidget(androidName: _focusWidgetName);
    await HomeWidget.updateWidget(androidName: _tasksWidgetName);
  }
}
