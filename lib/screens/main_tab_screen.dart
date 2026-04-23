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
            icon: Icon(CupertinoIcons.square_stack_3d_up),
            label: 'Baralhos',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: 'Navegar',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
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
          0 => const CupertinoTabView(builder: (_) => DeckListScreen()),
          1 => const CupertinoTabView(builder: (_) => BrowserScreen()),
          2 => const CupertinoTabView(builder: (_) => StatsScreen()),
          3 => const CupertinoTabView(builder: (_) => SettingsScreen()),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
