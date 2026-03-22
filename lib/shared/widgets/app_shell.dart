import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  DateTime? lastBackPressed;

  String _getModuleName(int index) {
    switch (index) {
      case 0:
        return 'DASHBOARD';
      case 1:
        return 'FOCUS';
      case 2:
        return 'HABITS';
      case 3:
        return 'TASKS';
      case 4:
        return 'CALENDAR';
      case 5:
        return 'NOTES';
      case 6:
        return 'SETTINGS';
      case 7:
        return 'PRO';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final currentIndex = navigationShell.currentIndex;

    final bottomNavDestinations = const [
      ('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
      ('Habits', Icons.track_changes_outlined, Icons.track_changes),
      ('Tasks', Icons.checklist_rtl_outlined, Icons.checklist_rtl),
      ('Calendar', Icons.calendar_month_outlined, Icons.calendar_month),
      ('Notes', Icons.sticky_note_2_outlined, Icons.sticky_note_2),
    ];

    const bottomNavBranchMap = [0, 2, 3, 4, 5];

    int getBottomNavIndex(int branchIndex) {
      return bottomNavBranchMap.indexOf(branchIndex);
    }

    final bottomNavIndex = getBottomNavIndex(currentIndex);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        // Always handle back navigation manually
        final navigationShell = widget.navigationShell;
        final currentIndex = navigationShell.currentIndex;
        if (currentIndex != 0) {
          navigationShell.goBranch(0);
          return;
        }
        final now = DateTime.now();
        if (lastBackPressed == null ||
            now.difference(lastBackPressed!) > const Duration(seconds: 2)) {
          lastBackPressed = now;
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        } else {
          Future.delayed(const Duration(milliseconds: 100), () {
            SystemNavigator.pop();
          });
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              navigationShell.goBranch(0);
            },
            child: Row(
              children: [
                Icon(
                  Icons.dashboard,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ZENiT',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      '// ${_getModuleName(currentIndex)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: 'Focus',
              onPressed: () {
                navigationShell.goBranch(1);
              },
              icon: Icon(
                currentIndex == 1 ? Icons.timer : Icons.timer_outlined,
              ),
            ),
            IconButton(
              tooltip: 'Pro',
              onPressed: () {
                navigationShell.goBranch(7);
              },
              icon: Icon(
                currentIndex == 7
                    ? Icons.workspace_premium
                    : Icons.workspace_premium_outlined,
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () {
                navigationShell.goBranch(6);
              },
              icon: Icon(
                currentIndex == 6 ? Icons.settings : Icons.settings_outlined,
              ),
            ),
          ],
        ),
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: bottomNavIndex >= 0 ? bottomNavIndex : 0,
          onDestinationSelected: (index) {
            final branchIndex = index < bottomNavBranchMap.length
                ? bottomNavBranchMap[index]
                : 0;
            navigationShell.goBranch(branchIndex);
          },
          destinations: bottomNavDestinations
              .map(
                ((String, IconData, IconData) item) => NavigationDestination(
                  icon: Icon(item.$2),
                  selectedIcon: Icon(item.$3),
                  label: item.$1,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
