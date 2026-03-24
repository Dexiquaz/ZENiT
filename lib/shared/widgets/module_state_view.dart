import 'package:flutter/material.dart';

class ModuleLoadingState extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ModuleLoadingState({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ModuleEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ModuleEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ModuleErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String retryLabel;
  final VoidCallback? onRetry;

  const ModuleErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.retryLabel = 'TRY AGAIN',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 30,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(retryLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ModuleInlineLoadingState extends StatelessWidget {
  final String label;

  const ModuleInlineLoadingState({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class ModuleInlineErrorState extends StatelessWidget {
  final String label;
  final VoidCallback? onRetry;
  final String retryLabel;

  const ModuleInlineErrorState({
    super.key,
    required this.label,
    this.onRetry,
    this.retryLabel = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 14,
          color: Theme.of(context).colorScheme.error,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(retryLabel.toUpperCase()),
          ),
      ],
    );
  }
}

class ModuleSkeletonBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const ModuleSkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ModuleChipRowSkeleton extends StatelessWidget {
  final int chipCount;

  const ModuleChipRowSkeleton({super.key, this.chipCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemBuilder: (_, index) {
        return ModuleSkeletonBlock(
          width: index == chipCount - 1 ? 108 : 78,
          height: 32,
          radius: 16,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemCount: chipCount,
    );
  }
}

class ModuleCardListSkeleton extends StatelessWidget {
  final int itemCount;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;

  const ModuleCardListSkeleton({
    super.key,
    this.itemCount = 5,
    this.horizontalPadding = 16,
    this.topPadding = 8,
    this.bottomPadding = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      itemBuilder: (_, __) {
        return Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ModuleSkeletonBlock(width: 120, height: 12, radius: 6),
                SizedBox(height: 12),
                ModuleSkeletonBlock(height: 16),
                SizedBox(height: 10),
                ModuleSkeletonBlock(width: 210, height: 12, radius: 6),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: itemCount,
    );
  }
}

class ModuleGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double padding;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  const ModuleGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.padding = 24,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(padding, padding, padding, 110),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ModuleSkeletonBlock(height: 14, radius: 7),
              SizedBox(height: 10),
              Expanded(child: ModuleSkeletonBlock(height: double.infinity)),
              SizedBox(height: 10),
              ModuleSkeletonBlock(width: 60, height: 10, radius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
