import 'package:flutter/cupertino.dart';
import '../src/rust/api.dart';

class DeckTile extends StatelessWidget {
  final DeckNode deck;
  final VoidCallback onTap;
  final int depth;

  const DeckTile({super.key, required this.deck, required this.onTap, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    final hasCards = deck.newCount + deck.learnCount + deck.dueCount > 0;

    return Column(
      children: [
        CupertinoListTile(
          padding: EdgeInsetsDirectional.fromSTEB(16.0 + depth * 16.0, 10, 16, 10),
          title: Text(
            _shortName(deck.name),
            style: TextStyle(
              fontWeight: hasCards ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (deck.newCount > 0) _Badge(deck.newCount, CupertinoColors.activeBlue),
              if (deck.learnCount > 0) ...[
                const SizedBox(width: 4),
                _Badge(deck.learnCount, CupertinoColors.systemRed),
              ],
              if (deck.dueCount > 0) ...[
                const SizedBox(width: 4),
                _Badge(deck.dueCount, CupertinoColors.activeGreen),
              ],
              if (!hasCards) ...[
                const SizedBox(width: 4),
                const Text('–', style: TextStyle(color: CupertinoColors.tertiaryLabel)),
              ],
            ],
          ),
          onTap: onTap,
        ),
        if (deck.children.isNotEmpty)
          ...deck.children.map((child) => DeckTile(
                deck: child,
                onTap: onTap,
                depth: depth + 1,
              )),
        if (depth == 0)
          Container(height: 0.5, margin: const EdgeInsetsDirectional.only(start: 16), color: CupertinoColors.separator),
      ],
    );
  }

  String _shortName(String fullName) {
    final parts = fullName.split('::');
    return parts.last;
  }
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;

  const _Badge(this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        count > 999 ? '999+' : count.toString(),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
