import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/anki_service.dart';
import '../src/rust/api.dart';

final currentDeckProvider = StateProvider<DeckNode?>((ref) => null);

final deckTreeProvider = AsyncNotifierProvider<DeckTreeNotifier, List<DeckNode>>(DeckTreeNotifier.new);

class DeckTreeNotifier extends AsyncNotifier<List<DeckNode>> {
  @override
  Future<List<DeckNode>> build() => AnkiService.instance.getDeckTree();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => AnkiService.instance.getDeckTree());
  }

  Future<void> addDeck(String name) async {
    await AnkiService.instance.addDeck(name);
    await refresh();
  }

  Future<void> deleteDeck(int id) async {
    await AnkiService.instance.deleteDeck(id);
    await refresh();
  }
}
