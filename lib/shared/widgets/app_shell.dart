import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _lastSelectedNavIndex = 0;

  Future<void> _handleBackPress(int currentIndex) async {
    if (currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      return;
    }

    final shouldExit =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit ZENiT?'),
            content: const Text('Do you want to close the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldExit) {
      SystemNavigator.pop();
    }
  }

  String _getModuleName(int index) {
    switch (index) {
      case 0:
        return 'DASHBOARD';
      case 1:
        return 'FOCUS';
      case 2:
        return 'SETTINGS';
      case 3:
        return 'HABITS';
      case 4:
        return 'TASKS';
      case 5:
        return 'JOURNAL';
      case 6:
        return 'FINANCE';
      case 7:
        return 'NOTES';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    // Keep bottom nav selection in sync for visible tabs only.
    if (currentIndex >= 0 && currentIndex <= 2) {
      _lastSelectedNavIndex = currentIndex;
    } else {
      _lastSelectedNavIndex = 0;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        await _handleBackPress(widget.navigationShell.currentIndex);
      },
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              widget.navigationShell.goBranch(0);
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
        ),
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _lastSelectedNavIndex,
          onDestinationSelected: (i) {
            widget.navigationShell.goBranch(i);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'DASHBOARD',
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'FOCUS',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
