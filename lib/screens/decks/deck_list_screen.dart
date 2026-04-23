import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/deck_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/deck_tile.dart';
import '../review/review_screen.dart';
import '../../src/rust/api.dart';

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckTreeAsync = ref.watch(deckTreeProvider);
    final syncState = ref.watch(syncStateProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Baralhos'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncState.isSyncing)
              const CupertinoActivityIndicator()
            else
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => ref.read(syncStateProvider.notifier).sync(),
                child: const Icon(CupertinoIcons.arrow_2_circlepath),
              ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showAddDeckDialog(context, ref),
              child: const Icon(CupertinoIcons.add),
            ),
          ],
        ),
      ),
      child: deckTreeAsync.when(
        data: (decks) => _DeckListBody(decks: decks),
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(
          child: Text('Erro: $e', style: const TextStyle(color: CupertinoColors.destructiveRed)),
        ),
      ),
    );
  }

  void _showAddDeckDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Novo Baralho'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(controller: controller, placeholder: 'Nome do baralho'),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(deckTreeProvider.notifier).addDeck(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}

class _DeckListBody extends ConsumerWidget {
  final List<DeckNode> decks;

  const _DeckListBody({required this.decks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (decks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.square_stack_3d_up, size: 64, color: CupertinoColors.secondaryLabel),
            SizedBox(height: 16),
            Text('Nenhum baralho encontrado', style: TextStyle(fontSize: 18, color: CupertinoColors.secondaryLabel)),
            SizedBox(height: 8),
            Text('Toque em + para criar um baralho', style: TextStyle(color: CupertinoColors.tertiaryLabel)),
          ],
        ),
      );
    }

    final totalNew = decks.fold(0, (s, d) => s + d.newCount);
    final totalLearn = decks.fold(0, (s, d) => s + d.learnCount);
    final totalDue = decks.fold(0, (s, d) => s + d.dueCount);

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => ref.read(syncStateProvider.notifier).sync(),
        ),
        SliverToBoxAdapter(
          child: _SummaryHeader(
            newCount: totalNew,
            learnCount: totalLearn,
            dueCount: totalDue,
            onStudyAll: totalNew + totalLearn + totalDue > 0
                ? () => _studyAll(context, ref, decks)
                : null,
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index < decks.length) {
                return DeckTile(
                  deck: decks[index],
                  onTap: () => _openDeck(context, ref, decks[index]),
                );
              }
              return null;
            },
            childCount: decks.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  void _openDeck(BuildContext context, WidgetRef ref, DeckNode deck) {
    if (deck.newCount + deck.learnCount + deck.dueCount == 0) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(deck.name),
          content: const Text('Não há cartões para revisar agora.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    ref.read(currentDeckProvider.notifier).state = deck;
    Navigator.push(context, CupertinoPageRoute(builder: (_) => ReviewScreen(deckId: deck.id, deckName: deck.name)));
  }

  void _studyAll(BuildContext context, WidgetRef ref, List<DeckNode> decks) {
    final firstDue = decks.firstWhere(
      (d) => d.newCount + d.learnCount + d.dueCount > 0,
      orElse: () => decks.first,
    );
    _openDeck(context, ref, firstDue);
  }
}

class _SummaryHeader extends StatelessWidget {
  final int newCount;
  final int learnCount;
  final int dueCount;
  final VoidCallback? onStudyAll;

  const _SummaryHeader({
    required this.newCount,
    required this.learnCount,
    required this.dueCount,
    this.onStudyAll,
  });

  @override
  Widget build(BuildContext context) {
    final hasCards = newCount + learnCount + dueCount > 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CountPill(label: 'Novos', count: newCount, color: CupertinoColors.activeBlue),
              _CountPill(label: 'Aprender', count: learnCount, color: CupertinoColors.systemRed),
              _CountPill(label: 'Revisar', count: dueCount, color: CupertinoColors.activeGreen),
            ],
          ),
          if (hasCards) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 10),
                onPressed: onStudyAll,
                child: Text('Estudar Tudo (${newCount + learnCount + dueCount})'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountPill({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel)),
      ],
    );
  }
}
