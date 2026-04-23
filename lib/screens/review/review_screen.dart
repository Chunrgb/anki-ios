import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../providers/review_provider.dart';
import '../../src/rust/api.dart';
import '../../widgets/answer_buttons.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final int deckId;
  final String deckName;

  const ReviewScreen({super.key, required this.deckId, required this.deckName});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> with SingleTickerProviderStateMixin {
  late final WebViewController _webController;
  late final AnimationController _flipController;
  bool _answerShown = false;
  DateTime? _cardStartTime;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(CupertinoColors.systemBackground);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewSessionProvider.notifier).startSession(widget.deckId);
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(reviewSessionProvider);

    ref.listen(reviewSessionProvider, (prev, next) {
      if (next.currentCard != null && next.currentCard != prev?.currentCard) {
        _loadCard(next.currentCard!, next.showAnswer);
        _cardStartTime = DateTime.now();
      }
      if (next.showAnswer != prev?.showAnswer && next.showAnswer) {
        _answerShown = true;
      }
    });

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.deckName),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showUndoConfirm(context),
          child: const Icon(CupertinoIcons.arrow_uturn_left),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _ProgressBar(session: session),
            Expanded(
              child: session.isComplete
                  ? _CompletionView(
                      studied: session.cardsStudied,
                      onClose: () => Navigator.pop(context),
                    )
                  : _CardView(
                      webController: _webController,
                      answerShown: _answerShown,
                      onShowAnswer: _showAnswer,
                    ),
            ),
            if (!session.isComplete)
              _answerShown
                  ? AnswerButtons(
                      onAnswer: (ease) => _answerCard(ease),
                      nextReviewTimes: session.nextReviewTimes,
                    )
                  : _ShowAnswerButton(onPressed: _showAnswer),
          ],
        ),
      ),
    );
  }

  void _loadCard(CardForReview card, bool showAnswer) {
    final html = _buildCardHtml(card.questionHtml, showAnswer ? card.answerHtml : null);
    _webController.loadHtmlString(html);
    setState(() => _answerShown = showAnswer);
  }

  void _showAnswer() {
    final notifier = ref.read(reviewSessionProvider.notifier);
    notifier.showAnswer();
    HapticFeedback.lightImpact();
  }

  void _answerCard(int ease) {
    final elapsed = _cardStartTime != null
        ? DateTime.now().difference(_cardStartTime!).inMilliseconds
        : 0;
    ref.read(reviewSessionProvider.notifier).answerCard(ease, elapsed);
    setState(() => _answerShown = false);
    HapticFeedback.mediumImpact();
  }

  void _showUndoConfirm(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Desfazer'),
        content: const Text('Desfazer a última resposta?'),
        actions: [
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          CupertinoDialogAction(
            onPressed: () {
              ref.read(reviewSessionProvider.notifier).undoLastAnswer();
              Navigator.pop(ctx);
            },
            child: const Text('Desfazer'),
          ),
        ],
      ),
    );
  }

  String _buildCardHtml(String questionHtml, String? answerHtml) {
    final answerBlock = answerHtml != null
        ? '<hr id="answer"><div class="card answer">$answerHtml</div>'
        : '';
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif;
    font-size: 18px;
    line-height: 1.5;
    color: #000;
    background: #fff;
    padding: 20px;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }
  @media (prefers-color-scheme: dark) {
    body { background: #1c1c1e; color: #fff; }
    hr { border-color: #3a3a3c; }
  }
  .card { width: 100%; max-width: 600px; text-align: center; }
  hr#answer { width: 100%; border: none; border-top: 1px solid #c6c6c8; margin: 20px 0; }
  img { max-width: 100%; height: auto; border-radius: 8px; }
  .cloze { color: #0a84ff; }
  code { background: rgba(0,0,0,0.1); padding: 2px 6px; border-radius: 4px; font-size: 0.9em; }
</style>
</head>
<body>
<div class="card question">$questionHtml</div>
$answerBlock
</body>
</html>
''';
  }
}

class _ProgressBar extends StatelessWidget {
  final ReviewSession session;

  const _ProgressBar({required this.session});

  @override
  Widget build(BuildContext context) {
    final total = session.totalCards;
    final done = session.cardsStudied;
    final progress = total > 0 ? done / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: CupertinoColors.systemFill,
                valueColor: const AlwaysStoppedAnimation(CupertinoColors.activeBlue),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$done / $total',
            style: const TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  final WebViewController webController;
  final bool answerShown;
  final VoidCallback onShowAnswer;

  const _CardView({required this.webController, required this.answerShown, required this.onShowAnswer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: answerShown ? null : onShowAnswer,
      child: WebViewWidget(controller: webController),
    );
  }
}

class _ShowAnswerButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ShowAnswerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          onPressed: onPressed,
          child: const Text('Mostrar Resposta'),
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  final int studied;
  final VoidCallback onClose;

  const _CompletionView({required this.studied, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill, size: 72, color: CupertinoColors.activeGreen),
            const SizedBox(height: 20),
            const Text('Parabéns!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Você revisou $studied cartão${studied != 1 ? 's' : ''} hoje.',
              style: const TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: onClose,
              child: const Text('Concluído'),
            ),
          ],
        ),
      ),
    );
  }
}
