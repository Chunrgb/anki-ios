// AUTO-GENERATED FILE — regenerate with:
//   flutter pub run flutter_rust_bridge_codegen generate
//
// This stub allows the project to be imported/analyzed before codegen runs.
// Replace with real generated file when building for device.
// ignore_for_file: unused_import

library frb_generated;

import 'api.dart';

abstract class AnkiBridgeApi {
  Future<void> openCollection({required String path});
  Future<void> closeCollection();
  Future<List<DeckNode>> getDeckTree();
  Future<DueCounts> getDueCounts({required int deckId});
  Future<CardForReview?> getNextCard({required int deckId});
  Future<void> answerCard({required int cardId, required int ease, required int timeTakenMs});
  Future<void> undoLastAnswer();
  Future<void> addDeck({required String name});
  Future<void> deleteDeck({required int deckId});
  Future<List<NoteInfo>> searchNotes({required String query, required int limit});
  Future<SyncStatus> syncCollection({required String username, required String password});
  Future<CollectionStats> getCollectionStats();
}

class RustLib {
  RustLib._();

  static final RustLib instance = RustLib._();
  late AnkiBridgeApi api;

  static Future<void> init() async {
    // Populated by flutter_rust_bridge_codegen at build time.
    // In development/testing, use the mock below.
    instance.api = _DevMockApi();
  }
}

// ─── Dev mock (used in Simulator / hot-reload) ───────────────────────────────

class _DevMockApi implements AnkiBridgeApi {
  @override
  Future<void> openCollection({required String path}) async {}

  @override
  Future<void> closeCollection() async {}

  @override
  Future<List<DeckNode>> getDeckTree() async => [
        const DeckNode(id: 1, name: 'Inglês', newCount: 20, learnCount: 3, dueCount: 15, children: [
          DeckNode(id: 2, name: 'Inglês::Vocabulário', newCount: 10, learnCount: 1, dueCount: 8, children: []),
          DeckNode(id: 3, name: 'Inglês::Gramática', newCount: 10, learnCount: 2, dueCount: 7, children: []),
        ]),
        const DeckNode(id: 4, name: 'Biologia', newCount: 5, learnCount: 0, dueCount: 12, children: []),
        const DeckNode(id: 5, name: 'Matemática', newCount: 0, learnCount: 0, dueCount: 0, children: []),
      ];

  @override
  Future<DueCounts> getDueCounts({required int deckId}) async =>
      const DueCounts(newCount: 20, learnCount: 3, dueCount: 15);

  @override
  Future<CardForReview?> getNextCard({required int deckId}) async => const CardForReview(
        id: 1001,
        questionHtml: '<p><b>What is the capital of France?</b></p>',
        answerHtml: '<p>Paris</p>',
        noteType: 'Basic',
      );

  @override
  Future<void> answerCard({required int cardId, required int ease, required int timeTakenMs}) async {}

  @override
  Future<void> undoLastAnswer() async {}

  @override
  Future<void> addDeck({required String name}) async {}

  @override
  Future<void> deleteDeck({required int deckId}) async {}

  @override
  Future<List<NoteInfo>> searchNotes({required String query, required int limit}) async => [
        const NoteInfo(id: 1, noteType: 'Basic', fields: ['What is the capital of France?', 'Paris'], tags: ['geography'], deckName: 'Inglês', due: 'hoje'),
        const NoteInfo(id: 2, noteType: 'Basic', fields: ['Photosynthesis', 'The process by which plants...'], tags: ['biology'], deckName: 'Biologia', due: 'amanhã'),
      ];

  @override
  Future<SyncStatus> syncCollection({required String username, required String password}) async =>
      const SyncStatus(success: true, message: 'Sync completo');

  @override
  Future<CollectionStats> getCollectionStats() async => CollectionStats(
        studiedToday: 47,
        studyTimeMinutes: 23,
        retentionRate: 0.91,
        streakDays: 14,
        forecast: List.generate(30, (i) => 20 + (i % 7) * 5),
      );
}
