import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ZenitAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titleSubtitle;
  final List<Widget>? actions;
  final bool isDashboard;

  const ZenitAppBar({
    super.key,
    required this.titleSubtitle,
    this.actions,
    this.isDashboard = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: InkWell(
        onTap: isDashboard ? null : () => context.go('/'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ZENiT',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  if (titleSubtitle.isNotEmpty)
                    Text(
                      '// $titleSubtitle',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
