import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/anki_service.dart';
import '../src/rust/api.dart';

final browserResultsProvider = AsyncNotifierProvider<BrowserNotifier, List<NoteInfo>>(BrowserNotifier.new);

class BrowserNotifier extends AsyncNotifier<List<NoteInfo>> {
  @override
  Future<List<NoteInfo>> build() async => [];

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => AnkiService.instance.searchNotes(query, 200));
  }
}
