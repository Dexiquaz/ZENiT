import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/services/notification_service.dart';
import 'core/services/widget_bridge_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/views/settings_view.dart';
import 'core/providers/pro_access_provider.dart';
import 'core/providers/settings_provider.dart';
import 'shared/widgets/app_shell.dart';
import 'features/dashboard/views/dashboard_view.dart';
import 'features/zen_mode/views/zen_mode_view.dart';
import 'features/zen_mode/providers/zen_mode_provider.dart';
import 'features/habit_tracker/views/habit_tracker_view.dart';
import 'features/todo/views/todo_view.dart';
import 'features/todo/models/task_model.dart';
import 'features/todo/providers/todo_provider.dart';
import 'features/calendar_journal/views/calendar_journal_view.dart';
import 'features/notes_shopping/views/notes_shopping_view.dart';
import 'features/pro/views/pro_view.dart';
import 'features/onboarding/views/onboarding_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (Platform.isAndroid || Platform.isIOS) {
    await NotificationService.instance.initialize();
    await WidgetBridgeService.initialize();
  }

  runApp(const ProviderScope(child: ZenitApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final settingsState = ref.read(settingsProvider);
      if (!settingsState.hasValue) return null;

      final settings = settingsState.value!;
      final isLoggingIn = state.matchedLocation == '/onboarding';

      if (!settings.hasCompletedOnboarding && !isLoggingIn) {
        return '/onboarding';
      }
      if (settings.hasCompletedOnboarding && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingView()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const DashboardView()),
            ],
          ),
          // 1: Focus (Zen Mode)
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/focus', builder: (_, __) => const ZenModeView()),
            ],
          ),
          // 2: Habits
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/habits',
                builder: (_, __) => const HabitTrackerView(),
              ),
            ],
          ),
          // 3: Tasks
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/tasks', builder: (_, __) => const TodoView()),
            ],
          ),
          // 4: Calendar & Journal
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (_, __) => const CalendarJournalView(),
              ),
            ],
          ),
          // 5: Notes & Shopping
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (_, __) => const NotesShoppingView(),
              ),
            ],
          ),
          // 6: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsView(),
              ),
            ],
          ),
          // 7: Pro
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/pro', builder: (_, __) => const ProView()),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/upgrade',
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('UPGRADE TO PRO'),
            leading: BackButton(onPressed: () => context.pop()),
          ),
          body: const ProView(),
        ),
      ),
    ],
  );
});

class ZenitApp extends ConsumerStatefulWidget {
  const ZenitApp({super.key});

  @override
  ConsumerState<ZenitApp> createState() => _ZenitAppState();
}

class _ZenitAppState extends ConsumerState<ZenitApp>
    with WidgetsBindingObserver {
  ProviderSubscription<ZenTimerState>? _focusSubscription;
  ProviderSubscription<AsyncValue<List<Task>>>? _taskSubscription;
  ProviderSubscription<AsyncValue<bool>>? _proSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (Platform.isAndroid || Platform.isIOS) {
      unawaited(ref.read(proAccessProvider.notifier).reconcileEntitlement());

      _focusSubscription = ref.listenManual<ZenTimerState>(
        zenTimerProvider,
        (_, __) => _syncWidgets(),
        fireImmediately: true,
      );

      _taskSubscription = ref.listenManual<AsyncValue<List<Task>>>(
        allTaskListProvider,
        (_, __) => _syncWidgets(),
        fireImmediately: true,
      );

      _proSubscription = ref.listenManual<AsyncValue<bool>>(
        proAccessProvider,
        (_, __) => _syncWidgets(),
        fireImmediately: true,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusSubscription?.close();
    _taskSubscription?.close();
    _proSubscription?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(proAccessProvider.notifier).reconcileEntitlement());
      unawaited(_syncWidgets());
    }
  }

  Future<void> _syncWidgets() async {
    try {
      final focusState = ref.read(zenTimerProvider);
      final taskState = ref.read(allTaskListProvider);
      final tasks = taskState.hasValue ? taskState.value! : <Task>[];
      final widgetGateAllowed = ref
          .read(proAccessProvider.notifier)
          .ambientViewDecision()
          .allowed;

      await WidgetBridgeService.syncFromState(
        canUseWidgets: widgetGateAllowed,
        focusState: focusState,
        tasks: tasks,
      );
    } catch (_) {
      await WidgetBridgeService.syncLockedState(canUseWidgets: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return settings.when(
      data: (s) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'ZENiT',
          theme: AppTheme.premiumLight,
          darkTheme: AppTheme.premiumDark,
          themeMode: ThemeMode.dark,
          routerConfig: ref.watch(routerProvider),
        );
      },
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  SizedBox(height: 16),
                  Text(
                    'ZENiT failed to start',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '$e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
