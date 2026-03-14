import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../shared/widgets/module_state_view.dart';
import '../../notes_shopping/providers/notes_provider.dart';
import '../../notes_shopping/models/models.dart';

class CalendarJournalView extends ConsumerStatefulWidget {
  const CalendarJournalView({super.key});
  @override
  ConsumerState<CalendarJournalView> createState() =>
      _CalendarJournalViewState();
}

class _CalendarJournalViewState extends ConsumerState<CalendarJournalView> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final journalState = ref.watch(journalProvider);
    final daysWithEntries = ref.watch(
      daysWithEntriesProvider(DateTime(_focusedDay.year, _focusedDay.month)),
    );
    final isToday = isSameDay(_selectedDay, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('CALENDAR JOURNAL'),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: isToday
            ? SizedBox(
                key: const ValueKey('fab'),
                width: MediaQuery.of(context).size.width - 48,
                height: 50,
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddEntryDialog(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('NEW ENTRY'),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Calendar Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Month Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setState(() {
                              _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month - 1,
                              );
                            });
                          },
                        ),
                        Text(
                          '${_focusedDay.year.toString()} ${_getMonthName(_focusedDay.month).toUpperCase()}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 1.5,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setState(() {
                              _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month + 1,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Calendar Grid
                    daysWithEntries.when(
                      data: (days) => _buildCalendarGrid(days),
                      loading: () => _buildCalendarGrid({}),
                      error: (_, __) => _buildCalendarGrid({}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Entries Section
            Text(
              'ENTRIES FOR ${_getMonthName(_selectedDay.month).toUpperCase()} ${_selectedDay.day}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            journalState.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const ModuleEmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'No entries for this day',
                    subtitle: 'Tap NEW ENTRY to log your day.',
                  );
                }
                return Column(
                  children: entries
                      .map((entry) => _EntryCard(entry: entry, ref: ref))
                      .toList(),
                );
              },
              loading: () => const ModuleLoadingState(
                title: 'Loading journal entries',
                subtitle: 'Checking entries for the selected day.',
              ),
              error: (_, __) => ModuleErrorState(
                title: 'Could not load journal entries',
                subtitle: 'Please try selecting the day again.',
                onRetry: () => ref.invalidate(journalProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    return months[month - 1];
  }

  Widget _buildCalendarGrid(Set<int> daysWithEntries) {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstDayOfWeek = firstDay.weekday - 1; // 0 = Monday
    final daysInMonth = lastDay.day;

    final days = List.generate(42, (index) {
      if (index < firstDayOfWeek || index >= firstDayOfWeek + daysInMonth) {
        return null;
      }
      return index - firstDayOfWeek + 1;
    });

    return Column(
      children: [
        // Day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        // Calendar days
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: days.map((day) {
            if (day == null) {
              return const SizedBox();
            }
            final date = DateTime(_focusedDay.year, _focusedDay.month, day);
            final isSelected = isSameDay(date, _selectedDay);
            final isToday = isSameDay(date, DateTime.now());

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDay = date;
                });
                ref.read(selectedDateProvider.notifier).select(date);
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected && !isToday
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                  color: isToday && isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      day.toString(),
                      style: TextStyle(
                        color: isToday && isSelected
                            ? Colors.black
                            : isToday && !isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    // Blue dot indicator (shown if has entries)
                    if (daysWithEntries.contains(day))
                      Positioned(
                        bottom: 2,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showAddEntryDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedMood = '😊';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'NEW ENTRY',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  // Mood selector
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                              // Happy/Positive
                              '😊', '😄', '🥰', '✨', '🌟',
                              // Calm/Meditative
                              '🧘', '😌', '🌙', '☮️',
                              // Tired/Rest
                              '😴', '🥱', '🛌',
                              // Active/Productive
                              '💪', '🎯', '🔥', '⚡', '🚀',
                              // Social
                              '👥', '💬', '🎉', '❤️',
                              // Creative
                              '🎨', '✍️', '💡', '📝',
                              // Nature/Mindful
                              '🌱', '🌻', '🌈', '🍃',
                              // Daily
                              '☕', '📚', '🎵', '🎮',
                            ]
                            .map(
                              (mood) => FilterChip(
                                label: Text(
                                  mood,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                selected: selectedMood == mood,
                                onSelected: (selected) {
                                  if (selected) setS(() => selectedMood = mood);
                                },
                                showCheckmark: false,
                              ),
                            )
                            .toList()
                          ..add(
                            FilterChip(
                              label: const Text('CUSTOM'),
                              selected: false,
                              onSelected: (_) {
                                showDialog(
                                  context: ctx,
                                  builder: (dialogCtx) {
                                    final controller = TextEditingController();
                                    return AlertDialog(
                                      title: const Text('CUSTOM EMOJI'),
                                      content: TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                          hintText: 'Enter any emoji',
                                          border: OutlineInputBorder(),
                                        ),
                                        maxLength: 2,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dialogCtx),
                                          child: const Text('CANCEL'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            if (controller.text.isNotEmpty) {
                                              setS(
                                                () => selectedMood =
                                                    controller.text,
                                              );
                                              Navigator.pop(dialogCtx);
                                            }
                                          },
                                          child: const Text('SET'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              showCheckmark: false,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Show selected mood
                  if (selectedMood.isNotEmpty)
                    Text(
                      'SELECTED: $selectedMood',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'TITLE',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'CONTENT',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        ref
                            .read(journalProvider.notifier)
                            .addEntry(
                              titleController.text,
                              contentController.text,
                              mood: selectedMood,
                            );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('SAVE ENTRY'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Standalone function for editing journal entries (can be called from any widget)
void _showEditEntryDialog(
  BuildContext context,
  WidgetRef ref,
  JournalEntry entry,
) {
  final titleController = TextEditingController(text: entry.title);
  final contentController = TextEditingController(text: entry.content);
  String selectedMood = entry.mood ?? '😊';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'EDIT ENTRY',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                // Mood selector
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                            // Happy/Positive
                            '😊', '😄', '🥰', '✨',
                            // Calm/Meditative
                            '🧘', '😌',
                            // Tired/Rest
                            '😴', '🥱', '🛌',
                            // Active/Productive
                            '💪', '🎯', '🔥', '⚡',
                            // Social
                            '👥', '💬', '🎉', '❤️',
                            // Creative
                            '🎨', '✍️', '💡', '📝',
                            // Nature/Mindful
                            '🌱', '🌻',
                            // Daily
                            '☕', '📚', '🎵', '🎮',
                          ]
                          .map(
                            (mood) => FilterChip(
                              label: Text(
                                mood,
                                style: const TextStyle(fontSize: 16),
                              ),
                              selected: selectedMood == mood,
                              onSelected: (selected) {
                                if (selected) setS(() => selectedMood = mood);
                              },
                              showCheckmark: false,
                            ),
                          )
                          .toList()
                        ..add(
                          FilterChip(
                            label: const Text('CUSTOM'),
                            selected: false,
                            onSelected: (_) {
                              showDialog(
                                context: context,
                                builder: (dialogCtx) {
                                  final controller = TextEditingController();
                                  return AlertDialog(
                                    title: const Text('CUSTOM EMOJI'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        hintText: 'Enter any emoji',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLength: 2,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (controller.text.isNotEmpty) {
                                            setS(
                                              () => selectedMood =
                                                  controller.text,
                                            );
                                            Navigator.pop(dialogCtx);
                                          }
                                        },
                                        child: const Text('SET'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            showCheckmark: false,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // Show selected mood
                if (selectedMood.isNotEmpty)
                  Text(
                    'SELECTED: $selectedMood',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'TITLE',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'CONTENT',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final updatedEntry = entry.copyWith(
                        title: titleController.text,
                        content: contentController.text,
                        mood: selectedMood,
                      );
                      ref
                          .read(journalProvider.notifier)
                          .updateEntry(updatedEntry);
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('UPDATE ENTRY'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final WidgetRef ref;

  const _EntryCard({required this.entry, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEntryOptions(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    entry.mood ?? '📝',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title.toUpperCase(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatTime(entry.timestamp),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (entry.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  entry.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('EDIT ENTRY'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditEntryDialog(context, ref, entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('DELETE ENTRY'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(journalProvider.notifier).deleteEntry(entry.id ?? 0);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
