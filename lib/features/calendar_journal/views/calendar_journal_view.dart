import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
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
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'NO ENTRIES FOR THIS DAY',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: entries
                      .map((entry) => _EntryCard(entry: entry, ref: ref))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('ERROR // $e')),
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
            left: 24,
            right: 24,
            top: 24,
          ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['😊', '🧘', '🌙', '😴', '💪', '🎯']
                    .map(
                      (mood) => GestureDetector(
                        onTap: () => setS(() => selectedMood = mood),
                        child: Text(
                          mood,
                          style: TextStyle(
                            fontSize: selectedMood == mood ? 32 : 24,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
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
    );
  }
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
        onLongPress: () => _showEntryOptions(context),
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
