import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_tab_screen.dart';
import 'providers/collection_provider.dart';

class AnkiApp extends ConsumerWidget {
  const AnkiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionAsync = ref.watch(collectionProvider);

    return CupertinoApp(
      title: 'Anki',
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: collectionAsync.when(
        data: (isOpen) => isOpen ? const MainTabScreen() : const _CollectionLoadingScreen(),
        loading: () => const _CollectionLoadingScreen(),
        error: (e, _) => _CollectionErrorScreen(error: e.toString()),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _CollectionLoadingScreen extends StatelessWidget {
  const _CollectionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(radius: 20),
            SizedBox(height: 16),
            Text('Carregando coleção...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _CollectionErrorScreen extends StatelessWidget {
  final String error;
  const _CollectionErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: CupertinoColors.destructiveRed),
              const SizedBox(height: 16),
              const Text('Erro ao abrir coleção', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
