import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/anki_service.dart';
import '../src/rust/api.dart';

class ReviewSession {
  final CardForReview? currentCard;
  final bool showAnswer;
  final bool isComplete;
  final int cardsStudied;
  final int totalCards;
  final List<String> nextReviewTimes;

  const ReviewSession({
    this.currentCard,
    this.showAnswer = false,
    this.isComplete = false,
    this.cardsStudied = 0,
    this.totalCards = 0,
    this.nextReviewTimes = const [],
  });

  ReviewSession copyWith({
    CardForReview? currentCard,
    bool? showAnswer,
    bool? isComplete,
    int? cardsStudied,
    int? totalCards,
    List<String>? nextReviewTimes,
    bool clearCard = false,
  }) {
    return ReviewSession(
      currentCard: clearCard ? null : currentCard ?? this.currentCard,
      showAnswer: showAnswer ?? this.showAnswer,
      isComplete: isComplete ?? this.isComplete,
      cardsStudied: cardsStudied ?? this.cardsStudied,
      totalCards: totalCards ?? this.totalCards,
      nextReviewTimes: nextReviewTimes ?? this.nextReviewTimes,
    );
  }
}

final reviewSessionProvider = StateNotifierProvider<ReviewSessionNotifier, ReviewSession>(
  (ref) => ReviewSessionNotifier(),
);

class ReviewSessionNotifier extends StateNotifier<ReviewSession> {
  ReviewSessionNotifier() : super(const ReviewSession());

  int? _currentDeckId;

  Future<void> startSession(int deckId) async {
    _currentDeckId = deckId;
    final counts = await AnkiService.instance.getDueCounts(deckId);
    final total = counts.newCount + counts.learnCount + counts.dueCount;

    state = ReviewSession(totalCards: total);
    await _loadNextCard();
  }

  Future<void> _loadNextCard() async {
    if (_currentDeckId == null) return;

    final card = await AnkiService.instance.getNextCard(_currentDeckId!);
    if (card == null) {
      state = state.copyWith(isComplete: true);
      return;
    }
    state = state.copyWith(currentCard: card, showAnswer: false);
  }

  void showAnswer() {
    if (state.currentCard == null) return;
    state = state.copyWith(showAnswer: true);
  }

  Future<void> answerCard(int ease, int timeTakenMs) async {
    final card = state.currentCard;
    if (card == null) return;

    await AnkiService.instance.answerCard(card.id, ease, timeTakenMs);
    state = state.copyWith(
      cardsStudied: state.cardsStudied + 1,
      showAnswer: false,
    );
    await _loadNextCard();
  }

  Future<void> undoLastAnswer() async {
    await AnkiService.instance.undoLastAnswer();
    if (state.cardsStudied > 0) {
      state = state.copyWith(cardsStudied: state.cardsStudied - 1);
    }
    await _loadNextCard();
  }
}
