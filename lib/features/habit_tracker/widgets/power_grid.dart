import 'package:flutter/material.dart';

class PowerGrid extends StatelessWidget {
  final List<DateTime> completionDates;
  final int daysToShow;

  const PowerGrid({
    super.key,
    required this.completionDates,
    this.daysToShow = 14,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final dates = List.generate(daysToShow, (index) {
      return today.subtract(Duration(days: daysToShow - 1 - index));
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: dates.map((date) {
        final isCompleted = completionDates.any(
          (d) =>
              d.year == date.year && d.month == date.month && d.day == date.day,
        );

        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isCompleted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border.all(
              color: isCompleted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}
