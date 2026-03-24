import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/module_state_view.dart';
import '../models/models.dart';
import '../providers/notes_provider.dart';

class NotesShoppingView extends ConsumerStatefulWidget {
  const NotesShoppingView({super.key});
  @override
  ConsumerState<NotesShoppingView> createState() => _NotesShoppingViewState();
}

class _NotesShoppingViewState extends ConsumerState<NotesShoppingView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'NOTES'),
              Tab(text: 'SHOPPING'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [_NotesTab(), _ShoppingTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesTab extends ConsumerWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(noteListProvider);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.sizeOf(context).width - 32,
        child: FloatingActionButton.extended(
          onPressed: () => _showNoteEditor(context, ref),
          label: const Text('NEW NOTE'),
          icon: const Icon(Icons.add),
        ),
      ),
      body: notes.when(
        data: (list) => list.isEmpty
            ? ModuleEmptyState(
                icon: Icons.note_alt_outlined,
                title: 'No notes yet',
                subtitle:
                    'Capture your first thought, idea, or reminder using NEW NOTE.',
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 900
                      ? 4
                      : MediaQuery.sizeOf(context).width > 600
                      ? 3
                      : 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) => _NoteCard(
                  note: list[i],
                  onTap: () => _showNoteEditor(context, ref, note: list[i]),
                ),
              ),
        loading: () {
          final width = MediaQuery.sizeOf(context).width;
          final crossAxisCount = width > 900
              ? 4
              : width > 600
              ? 3
              : 2;
          return ModuleGridSkeleton(
            crossAxisCount: crossAxisCount,
            itemCount: crossAxisCount * 3,
          );
        },
        error: (_, __) => ModuleErrorState(
          title: 'Could not load notes',
          subtitle: 'Please try refreshing notes.',
          onRetry: () => ref.invalidate(noteListProvider),
        ),
      ),
    );
  }

  void _showNoteEditor(BuildContext context, WidgetRef ref, {Note? note}) {
    final titleC = TextEditingController(text: note?.title);
    final contentC = TextEditingController(text: note?.content);
    final listItems = note?.listItems != null
        ? List<NoteListItem>.from(note!.listItems)
        : <NoteListItem>[];
    final listItemControllers = <TextEditingController>[];
    for (final item in listItems) {
      listItemControllers.add(TextEditingController(text: item.text));
    }
    NoteType type = note?.type ?? NoteType.text;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
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
                note == null ? 'NEW NOTE' : 'EDIT NOTE',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ToggleButtons(
                isSelected: [type == NoteType.text, type == NoteType.list],
                onPressed: (idx) {
                  setState(() {
                    type = idx == 0 ? NoteType.text : NoteType.list;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Text'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('List'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleC,
                style: Theme.of(context).textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'TITLE',
                  border: InputBorder.none,
                ),
                autofocus: note == null,
              ),
              const Divider(),
              if (type == NoteType.text)
                Flexible(
                  child: TextField(
                    controller: contentC,
                    maxLines: null,
                    style: Theme.of(context).textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: 'START TYPING...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              if (type == NoteType.list)
                Flexible(
                  child: Column(
                    children: [
                      for (int i = 0; i < listItemControllers.length; i++)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: listItemControllers[i],
                                decoration: InputDecoration(
                                  hintText: 'List item',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                setState(() {
                                  listItemControllers.removeAt(i);
                                  listItems.removeAt(i);
                                });
                              },
                            ),
                          ],
                        ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            listItemControllers.add(TextEditingController());
                            listItems.add(NoteListItem(text: ''));
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add item'),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final title = titleC.text.isEmpty
                          ? 'UNTITLED'
                          : titleC.text;
                      if (type == NoteType.text) {
                        if (titleC.text.isNotEmpty ||
                            contentC.text.isNotEmpty) {
                          if (note == null) {
                            ref
                                .read(noteListProvider.notifier)
                                .addNote(
                                  Note(
                                    title: title,
                                    content: contentC.text,
                                    type: NoteType.text,
                                    createdAt: DateTime.now(),
                                  ),
                                );
                          } else {
                            ref
                                .read(noteListProvider.notifier)
                                .updateNote(
                                  note.copyWith(
                                    title: title,
                                    content: contentC.text,
                                    type: NoteType.text,
                                  ),
                                );
                          }
                          Navigator.pop(ctx);
                        }
                      } else {
                        // List note
                        final items = <NoteListItem>[];
                        for (final c in listItemControllers) {
                          final text = c.text.trim();
                          if (text.isNotEmpty) {
                            items.add(NoteListItem(text: text));
                          }
                        }
                        if (titleC.text.isNotEmpty || items.isNotEmpty) {
                          if (note == null) {
                            ref
                                .read(noteListProvider.notifier)
                                .addNote(
                                  Note(
                                    title: title,
                                    listItems: items,
                                    type: NoteType.list,
                                    createdAt: DateTime.now(),
                                  ),
                                );
                          } else {
                            ref
                                .read(noteListProvider.notifier)
                                .updateNote(
                                  note.copyWith(
                                    title: title,
                                    listItems: items,
                                    type: NoteType.list,
                                  ),
                                );
                          }
                          Navigator.pop(ctx);
                        }
                      }
                    },
                    child: const Text('SAVE'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final Note note;
  final VoidCallback onTap;
  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    note.type == NoteType.list ? Icons.checklist : Icons.notes,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: note.type == NoteType.text
                    ? Text(
                        note.content,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.fade,
                      )
                    : ListView.builder(
                        itemCount: note.listItems.length,
                        itemBuilder: (ctx, i) => Row(
                          children: [
                            Icon(
                              note.listItems[i].checked
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                note.listItems[i].text,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d').format(note.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'DELETE NOTE',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () => ref
                        .read(noteListProvider.notifier)
                        .deleteNote(note.id!),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShoppingTab extends ConsumerWidget {
  const _ShoppingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(noteListProvider);
    return notesAsync.when(
      data: (notes) {
        // Find or create the shopping list note
        Note? shoppingNote = notes.firstWhere(
          (n) => n.type == NoteType.list && n.title == 'Shopping List',
          orElse: () => Note(
            title: 'Shopping List',
            listItems: [],
            type: NoteType.list,
            createdAt: DateTime.now(),
          ),
        );
        final items = shoppingNote.listItems;
        final unchecked = items.where((i) => !i.checked).toList();
        final checked = items.where((i) => i.checked).toList();
        return Scaffold(
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: SizedBox(
            width: MediaQuery.sizeOf(context).width - 32,
            child: FloatingActionButton.extended(
              onPressed: () => _showAddItemEditor(context, ref, shoppingNote),
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('NEW ITEM'),
            ),
          ),
          body: items.isEmpty
              ? const ModuleEmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Shopping list is empty',
                  subtitle: 'Add items using NEW ITEM.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  children: [
                    ...unchecked.asMap().entries.map(
                      (entry) => _ShoppingTile(
                        note: shoppingNote,
                        index: entry.key,
                        item: entry.value,
                        ref: ref,
                      ),
                    ),
                    if (checked.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 8, left: 8),
                        child: Text('COMPLETED'),
                      ),
                      ...checked.asMap().entries.map(
                        (entry) => _ShoppingTile(
                          note: shoppingNote,
                          index: unchecked.length + entry.key,
                          item: entry.value,
                          ref: ref,
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
      loading: () => const ModuleCardListSkeleton(
        itemCount: 7,
        horizontalPadding: 16,
        topPadding: 16,
        bottomPadding: 110,
      ),
      error: (_, __) => ModuleErrorState(
        title: 'Could not load shopping list',
        subtitle: 'Please try refreshing the list.',
        onRetry: () => ref.invalidate(noteListProvider),
      ),
    );
  }

  void _showAddItemEditor(BuildContext context, WidgetRef ref, Note note) {
    final nameController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
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
            Text('NEW ITEM', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ITEM NAME',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) =>
                  _submitNewItem(ctx, ref, note, nameController),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () =>
                      _submitNewItem(ctx, ref, note, nameController),
                  child: const Text('ADD'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _submitNewItem(
    BuildContext sheetContext,
    WidgetRef ref,
    Note note,
    TextEditingController controller,
  ) {
    final name = controller.text.trim();
    if (name.isEmpty) return;
    final updatedItems = List<NoteListItem>.from(note.listItems)
      ..add(NoteListItem(text: name));
    final updatedNote = note.copyWith(listItems: updatedItems);
    if (note.id == null) {
      ref.read(noteListProvider.notifier).addNote(updatedNote);
    } else {
      ref.read(noteListProvider.notifier).updateNote(updatedNote);
    }
    Navigator.pop(sheetContext);
  }
}

class _ShoppingTile extends StatelessWidget {
  final Note note;
  final int index;
  final NoteListItem item;
  final WidgetRef ref;
  const _ShoppingTile({
    required this.note,
    required this.index,
    required this.item,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: item.checked
          ? Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(60)
          : Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: Checkbox(
          value: item.checked,
          onChanged: (v) {
            final updatedItems = List<NoteListItem>.from(note.listItems);
            updatedItems[index] = item.copyWith(checked: v ?? false);
            ref
                .read(noteListProvider.notifier)
                .updateNote(note.copyWith(listItems: updatedItems));
          },
        ),
        title: Text(
          item.text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            decoration: item.checked ? TextDecoration.lineThrough : null,
            color: item.checked
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: () {
            final updatedItems = List<NoteListItem>.from(note.listItems)
              ..removeAt(index);
            ref
                .read(noteListProvider.notifier)
                .updateNote(note.copyWith(listItems: updatedItems));
          },
        ),
      ),
    );
  }
}
