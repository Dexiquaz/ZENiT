import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

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
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;

    // Primary bottom nav destinations (Focus is a separate quick action)
    final bottomNavDestinations = const [
      ('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
      ('Habits', Icons.track_changes_outlined, Icons.track_changes),
      ('Tasks', Icons.checklist_rtl_outlined, Icons.checklist_rtl),
      ('Calendar', Icons.calendar_month_outlined, Icons.calendar_month),
      ('Notes', Icons.sticky_note_2_outlined, Icons.sticky_note_2),
    ];

    // Map branch index <-> bottom nav visible index
    const bottomNavBranchMap = [0, 2, 3, 4, 6];

    int getBottomNavIndex(int branchIndex) {
      return bottomNavBranchMap.indexOf(branchIndex); // -1 if not in bottom nav
    }

    final bottomNavIndex = getBottomNavIndex(currentIndex);

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (currentIndex != 0) {
          navigationShell.goBranch(0); // Go to Dashboard
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
