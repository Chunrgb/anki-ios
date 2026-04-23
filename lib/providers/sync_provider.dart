import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/anki_service.dart';

class SyncState {
  final bool isSyncing;
  final bool isLoggedIn;
  final String? username;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const SyncState({
    this.isSyncing = false,
    this.isLoggedIn = false,
    this.username,
    this.lastSyncTime,
    this.errorMessage,
  });

  SyncState copyWith({bool? isSyncing, bool? isLoggedIn, String? username, DateTime? lastSyncTime, String? errorMessage}) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      username: username ?? this.username,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage,
    );
  }
}

final syncStateProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) => SyncNotifier());

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(const SyncState()) {
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('ankiweb_username');
    if (username != null && username.isNotEmpty) {
      state = state.copyWith(isLoggedIn: true, username: username);
    }
  }

  Future<void> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) return;

    state = state.copyWith(isSyncing: true);
    try {
      final result = await AnkiService.instance.syncCollection(username, password);
      if (result.success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('ankiweb_username', username);
        await prefs.setString('ankiweb_password', password);
        state = state.copyWith(
          isLoggedIn: true,
          username: username,
          isSyncing: false,
          lastSyncTime: DateTime.now(),
        );
      } else {
        state = state.copyWith(isSyncing: false, errorMessage: result.message);
      }
    } catch (e) {
      state = state.copyWith(isSyncing: false, errorMessage: e.toString());
    }
  }

  Future<void> sync() async {
    if (!state.isLoggedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('ankiweb_username') ?? '';
    final password = prefs.getString('ankiweb_password') ?? '';

    state = state.copyWith(isSyncing: true);
    try {
      await AnkiService.instance.syncCollection(username, password);
      state = state.copyWith(isSyncing: false, lastSyncTime: DateTime.now());
    } catch (e) {
      state = state.copyWith(isSyncing: false, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ankiweb_username');
    await prefs.remove('ankiweb_password');
    state = const SyncState();
  }
}
