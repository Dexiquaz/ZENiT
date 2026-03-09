import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/views/settings_view.dart';
import 'core/providers/settings_provider.dart';
import 'shared/widgets/app_shell.dart';
import 'features/dashboard/views/dashboard_view.dart';
import 'features/zen_mode/views/zen_mode_view.dart';
import 'features/habit_tracker/views/habit_tracker_view.dart';
import 'features/todo/views/todo_view.dart';
import 'features/calendar_journal/views/calendar_journal_view.dart';
import 'features/finance/views/finance_view.dart';
import 'features/notes_shopping/views/notes_shopping_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (Platform.isAndroid || Platform.isIOS) {
    await NotificationService.instance.initialize();
  }

  runApp(const ProviderScope(child: PersonalOrganizerApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (_, __) => const DashboardView()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/focus', builder: (_, __) => const ZenModeView()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/habits',
              builder: (_, __) => const HabitTrackerView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/tasks', builder: (_, __) => const TodoView()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              builder: (_, __) => const CalendarJournalView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/finance', builder: (_, __) => const FinanceView()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/notes',
              builder: (_, __) => const NotesShoppingView(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class PersonalOrganizerApp extends ConsumerWidget {
  const PersonalOrganizerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return settings.when(
      data: (s) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'ZENiT',
          theme: AppTheme.premiumDark,
          themeMode: ThemeMode.dark,
          routerConfig: _router,
        );
      },
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(body: Center(child: Text('INIT_ERROR // $e'))),
      ),
    );
  }
}
