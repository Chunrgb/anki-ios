import 'package:flutter/cupertino.dart';
import 'decks/deck_list_screen.dart';
import 'browser/browser_screen.dart';
import 'stats/stats_screen.dart';
import 'settings/settings_screen.dart';

class MainTabScreen extends StatelessWidget {
  const MainTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_stack),
            label: 'Baralhos',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: 'Navegar',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.graph_circle),
            label: 'Estatísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.gear),
            label: 'Ajustes',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return switch (index) {
          0 => CupertinoTabView(builder: (_) => const DeckListScreen()),
          1 => CupertinoTabView(builder: (_) => const BrowserScreen()),
          2 => CupertinoTabView(builder: (_) => const StatsScreen()),
          3 => CupertinoTabView(builder: (_) => const SettingsScreen()),
          _ => CupertinoTabView(builder: (_) => const SizedBox.shrink()),
        };
      },
    );
  }
}
