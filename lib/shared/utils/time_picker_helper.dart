import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Helper for showing an iOS-style time picker with spinner/slider interface
Future<TimeOfDay?> showZenitTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  TimePickerEntryMode initialEntryMode = TimePickerEntryMode.dial,
}) async {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return _CupertinoStyleTimePicker(initialTime: initialTime);
    },
  );
}

class _CupertinoStyleTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;

  const _CupertinoStyleTimePicker({required this.initialTime});

  @override
  State<_CupertinoStyleTimePicker> createState() =>
      _CupertinoStyleTimePickerState();
}

class _CupertinoStyleTimePickerState extends State<_CupertinoStyleTimePicker> {
  late int selectedHour;
  late int selectedMinute;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CANCEL',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text('SELECT TIME', style: theme.textTheme.titleLarge),
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      TimeOfDay(hour: selectedHour, minute: selectedMinute),
                    );
                  },
                  child: Text(
                    'OK',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Picker
          SizedBox(
            height: 260,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hour picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: selectedHour,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        selectedHour = index;
                      });
                    },
                    children: List<Widget>.generate(24, (int index) {
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Colon separator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    ':',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Minute picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: selectedMinute,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      setState(() {
                        selectedMinute = index;
                      });
                    },
                    children: List<Widget>.generate(60, (int index) {
                      return Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // Bottom padding
        ],
      ),
    );
  }
}
