// AUTO-GENERATED FILE — regenerate with:
//   flutter pub run flutter_rust_bridge_codegen generate
//
// This stub is committed so the project can be analyzed/edited without
// running codegen first.  The real generated file replaces this at build time.
// ignore_for_file: invalid_annotation_target, unused_element

library anki_bridge;

import 'frb_generated.dart';

// ─── Types ─────────────────────────────────────────────────────────────────

class DeckNode {
  final int id;
  final String name;
  final int newCount;
  final int learnCount;
  final int dueCount;
  final List<DeckNode> children;

  const DeckNode({
    required this.id,
    required this.name,
    required this.newCount,
    required this.learnCount,
    required this.dueCount,
    required this.children,
  });
}

class DueCounts {
  final int newCount;
  final int learnCount;
  final int dueCount;
  const DueCounts({required this.newCount, required this.learnCount, required this.dueCount});
}

class CardForReview {
  final int id;
  final String questionHtml;
  final String answerHtml;
  final String noteType;
  const CardForReview({required this.id, required this.questionHtml, required this.answerHtml, required this.noteType});
}

class NoteInfo {
  final int id;
  final String noteType;
  final List<String> fields;
  final List<String> tags;
  final String deckName;
  final String due;
  const NoteInfo({required this.id, required this.noteType, required this.fields, required this.tags, required this.deckName, required this.due});
}

class SyncStatus {
  final bool success;
  final String message;
  const SyncStatus({required this.success, required this.message});
}

class CollectionStats {
  final int studiedToday;
  final int studyTimeMinutes;
  final double retentionRate;
  final int streakDays;
  final List<int> forecast;
  const CollectionStats({required this.studiedToday, required this.studyTimeMinutes, required this.retentionRate, required this.streakDays, required this.forecast});
}

// ─── Bridge calls (delegated to generated code) ──────────────────────────────

Future<void> openCollection({required String path}) =>
    RustLib.instance.api.openCollection(path: path);

Future<void> closeCollection() =>
    RustLib.instance.api.closeCollection();

Future<List<DeckNode>> getDeckTree() =>
    RustLib.instance.api.getDeckTree();

Future<DueCounts> getDueCounts({required int deckId}) =>
    RustLib.instance.api.getDueCounts(deckId: deckId);

Future<CardForReview?> getNextCard({required int deckId}) =>
    RustLib.instance.api.getNextCard(deckId: deckId);

Future<void> answerCard({required int cardId, required int ease, required int timeTakenMs}) =>
    RustLib.instance.api.answerCard(cardId: cardId, ease: ease, timeTakenMs: timeTakenMs);

Future<void> undoLastAnswer() =>
    RustLib.instance.api.undoLastAnswer();

Future<void> addDeck({required String name}) =>
    RustLib.instance.api.addDeck(name: name);

Future<void> deleteDeck({required int deckId}) =>
    RustLib.instance.api.deleteDeck(deckId: deckId);

Future<List<NoteInfo>> searchNotes({required String query, required int limit}) =>
    RustLib.instance.api.searchNotes(query: query, limit: limit);

Future<SyncStatus> syncCollection({required String username, required String password}) =>
    RustLib.instance.api.syncCollection(username: username, password: password);

Future<CollectionStats> getCollectionStats() =>
    RustLib.instance.api.getCollectionStats();
