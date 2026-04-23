import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/browser_provider.dart';
import '../../src/rust/api.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(browserResultsProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Navegar')),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Buscar cartões (ex: deck:Inglês)',
                onSubmitted: (q) => ref.read(browserResultsProvider.notifier).search(q),
                onChanged: (q) {
                  if (q.isEmpty) ref.read(browserResultsProvider.notifier).search('');
                },
              ),
            ),
            Expanded(
              child: results.when(
                data: (notes) => notes.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => Container(height: 0.5, margin: const EdgeInsetsDirectional.only(start: 16), color: CupertinoColors.separator),
                        itemBuilder: (ctx, i) => _NoteRow(note: notes[i]),
                      ),
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final NoteInfo note;

  const _NoteRow({required this.note});

  @override
  Widget build(BuildContext context) {
    final front = note.fields.isNotEmpty ? note.fields[0] : '(sem conteúdo)';
    final back = note.fields.length > 1 ? note.fields[1] : '';

    return CupertinoListTile(
      title: Text(
        front,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(back, maxLines: 1, overflow: TextOverflow.ellipsis),
          Row(
            children: [
              _Tag(note.deckName, color: CupertinoColors.activeBlue.withOpacity(0.15)),
              const SizedBox(width: 6),
              _Tag('Vence: ${note.due}', color: CupertinoColors.systemGreen.withOpacity(0.15)),
            ],
          ),
        ],
      ),
      trailing: const CupertinoListTileChevron(),
      onTap: () => _showNoteDetail(context, note),
    );
  }

  void _showNoteDetail(BuildContext context, NoteInfo note) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _NoteDetailSheet(note: note),
    );
  }
}

class _NoteDetailSheet extends StatelessWidget {
  final NoteInfo note;

  const _NoteDetailSheet({required this.note});

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: Text(note.noteType),
      message: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < note.fields.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Campo ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(note.fields[i]),
                ],
              ),
            ),
          if (note.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Tags: ${note.tags.join(', ')}', style: const TextStyle(color: CupertinoColors.secondaryLabel)),
          ],
        ],
      ),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: const Text('Fechar'),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag(this.label, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.search, size: 48, color: CupertinoColors.secondaryLabel),
          SizedBox(height: 12),
          Text('Busque cartões acima', style: TextStyle(color: CupertinoColors.secondaryLabel)),
        ],
      ),
    );
  }
}
