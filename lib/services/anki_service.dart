import '../src/rust/api.dart' as bridge;
import '../providers/stats_provider.dart';

class AnkiService {
  AnkiService._();
  static final AnkiService instance = AnkiService._();

  Future<void> openCollection(String path) => bridge.openCollection(path: path);

  Future<void> closeCollection() => bridge.closeCollection();

  Future<List<bridge.DeckNode>> getDeckTree() => bridge.getDeckTree();

  Future<bridge.DueCounts> getDueCounts(int deckId) => bridge.getDueCounts(deckId: deckId);

  Future<bridge.CardForReview?> getNextCard(int deckId) => bridge.getNextCard(deckId: deckId);

  Future<void> answerCard(int cardId, int ease, int timeTakenMs) =>
      bridge.answerCard(cardId: cardId, ease: ease, timeTakenMs: timeTakenMs);

  Future<void> undoLastAnswer() => bridge.undoLastAnswer();

  Future<void> addDeck(String name) => bridge.addDeck(name: name);

  Future<void> deleteDeck(int id) => bridge.deleteDeck(deckId: id);

  Future<List<bridge.NoteInfo>> searchNotes(String query, int limit) =>
      bridge.searchNotes(query: query, limit: limit);

  Future<bridge.SyncStatus> syncCollection(String username, String password) =>
      bridge.syncCollection(username: username, password: password);

  Future<AnkiStats> getStats() async {
    final raw = await bridge.getCollectionStats();
    return AnkiStats(
      studiedToday: raw.studiedToday,
      studyTimeMinutes: raw.studyTimeMinutes,
      retentionRate: raw.retentionRate,
      streakDays: raw.streakDays,
      forecast: raw.forecast,
    );
  }
}
