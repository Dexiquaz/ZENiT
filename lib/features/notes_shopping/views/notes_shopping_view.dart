import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteEditor(context, ref),
        label: const Text('NEW NOTE'),
        icon: const Icon(Icons.add),
      ),
      body: notes.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Text(
                  'NO NOTES FOUND',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(24),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('ERROR // $e')),
      ),
    );
  }

  void _showNoteEditor(BuildContext context, WidgetRef ref, {Note? note}) {
    final titleC = TextEditingController(text: note?.title);
    final contentC = TextEditingController(text: note?.content);

    showModalBottomSheet(
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
            Text(
              note == null ? 'NEW NOTE' : 'EDIT NOTE',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
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
                    if (titleC.text.isNotEmpty || contentC.text.isNotEmpty) {
                      final title = titleC.text.isEmpty
                          ? 'UNTITLED'
                          : titleC.text;
                      if (note == null) {
                        ref
                            .read(noteListProvider.notifier)
                            .addNote(
                              Note(
                                title: title,
                                content: contentC.text,
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
                              ),
                            );
                      }
                      Navigator.pop(ctx);
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
              Text(
                note.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.fade,
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
                    visualDensity: VisualDensity.compact,
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
    final items = ref.watch(shoppingListProvider);
    final addController = TextEditingController();

    return Column(
      children: [
        Expanded(
          child: items.when(
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'SHOPPING LIST EMPTY',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                );
              }
              final unchecked = list.where((i) => !i.checked).toList();
              final checked = list.where((i) => i.checked).toList();
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...unchecked.map((i) => _ShoppingTile(item: i)),
                  if (checked.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 24, bottom: 8, left: 8),
                      child: Text('COMPLETED'),
                    ),
                    ...checked.map((i) => _ShoppingTile(item: i)),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('ERROR // $e')),
          ),
        ),
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: addController,
              decoration: InputDecoration(
                hintText: 'ADD ITEM',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (addController.text.isNotEmpty) {
                      ref
                          .read(shoppingListProvider.notifier)
                          .addItem(ShoppingItem(name: addController.text));
                      addController.clear();
                    }
                  },
                ),
              ),
              onSubmitted: (v) {
                if (v.isNotEmpty) {
                  ref
                      .read(shoppingListProvider.notifier)
                      .addItem(ShoppingItem(name: v));
                  addController.clear();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ShoppingTile extends ConsumerWidget {
  final ShoppingItem item;
  const _ShoppingTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: item.checked
          ? Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: Checkbox(
          value: item.checked,
          onChanged: (v) =>
              ref.read(shoppingListProvider.notifier).toggleItem(item),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.checked ? TextDecoration.lineThrough : null,
            color: item.checked
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: item.quantity > 1
                  ? () => ref
                        .read(shoppingListProvider.notifier)
                        .updateQuantity(item, item.quantity - 1)
                  : null,
            ),
            Text('${item.quantity}'),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => ref
                  .read(shoppingListProvider.notifier)
                  .updateQuantity(item, item.quantity + 1),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () =>
                  ref.read(shoppingListProvider.notifier).deleteItem(item.id!),
            ),
          ],
        ),
      ),
    );
  }
}
