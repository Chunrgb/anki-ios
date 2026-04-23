import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/sync_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final settings = ref.watch(settingsProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Ajustes')),
      child: SafeArea(
        child: ListView(
          children: [
            _SectionHeader('AnkiWeb'),
            if (syncState.isLoggedIn)
              _LoggedInTile(
                email: syncState.username ?? '',
                onSync: () => ref.read(syncStateProvider.notifier).sync(),
                onLogout: () => ref.read(syncStateProvider.notifier).logout(),
                isSyncing: syncState.isSyncing,
                lastSync: syncState.lastSyncTime,
              )
            else
              _LoginTile(onLogin: () => _showLoginDialog(context, ref)),

            _SectionHeader('Visualização'),
            CupertinoListTile(
              title: const Text('Tamanho da fonte'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${settings.fontSize.toInt()}px', style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                  const CupertinoListTileChevron(),
                ],
              ),
              onTap: () => _showFontSizeDialog(context, ref, settings.fontSize),
            ),
            CupertinoListTile(
              title: const Text('Modo escuro'),
              trailing: CupertinoSwitch(
                value: settings.darkMode,
                onChanged: (v) => ref.read(settingsProvider.notifier).setDarkMode(v),
              ),
            ),

            _SectionHeader('Estudo'),
            CupertinoListTile(
              title: const Text('Mostrar tempo de estudo'),
              trailing: CupertinoSwitch(
                value: settings.showStudyTimer,
                onChanged: (v) => ref.read(settingsProvider.notifier).setShowStudyTimer(v),
              ),
            ),
            CupertinoListTile(
              title: const Text('Atalhos de gestos'),
              subtitle: const Text('Deslize ← Again | Deslize → Good'),
              trailing: CupertinoSwitch(
                value: settings.swipeGestures,
                onChanged: (v) => ref.read(settingsProvider.notifier).setSwipeGestures(v),
              ),
            ),

            _SectionHeader('Dados'),
            CupertinoListTile(
              title: const Text('Exportar coleção (.colpkg)'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => _exportCollection(context, ref),
            ),
            CupertinoListTile(
              title: const Text('Importar baralho (.apkg)'),
              trailing: const CupertinoListTileChevron(),
              onTap: () => _importApkg(context, ref),
            ),

            _SectionHeader('Sobre'),
            CupertinoListTile(
              title: const Text('Versão'),
              trailing: const Text('1.0.0', style: TextStyle(color: CupertinoColors.secondaryLabel)),
            ),
            CupertinoListTile(
              title: const Text('Licença'),
              subtitle: const Text('AGPL-3.0'),
              trailing: const CupertinoListTileChevron(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context, WidgetRef ref) {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Entrar no AnkiWeb'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            CupertinoTextField(controller: usernameCtrl, placeholder: 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 8),
            CupertinoTextField(controller: passwordCtrl, placeholder: 'Senha', obscureText: true),
          ],
        ),
        actions: [
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          CupertinoDialogAction(
            onPressed: () {
              ref.read(syncStateProvider.notifier).login(usernameCtrl.text, passwordCtrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context, WidgetRef ref, double current) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(ctx)),
                CupertinoButton(child: const Text('OK'), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: (current - 12).toInt()),
                itemExtent: 36,
                onSelectedItemChanged: (i) => ref.read(settingsProvider.notifier).setFontSize((i + 12).toDouble()),
                children: [for (var i = 12; i <= 32; i++) Center(child: Text('${i}px'))],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCollection(BuildContext context, WidgetRef ref) async {
    // TODO: P2 — trigger rslib export + share sheet
  }

  Future<void> _importApkg(BuildContext context, WidgetRef ref) async {
    // TODO: P2 — file picker + rslib import
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CupertinoColors.secondaryLabel, letterSpacing: 0.5),
      ),
    );
  }
}

class _LoggedInTile extends StatelessWidget {
  final String email;
  final VoidCallback onSync;
  final VoidCallback onLogout;
  final bool isSyncing;
  final DateTime? lastSync;

  const _LoggedInTile({required this.email, required this.onSync, required this.onLogout, required this.isSyncing, this.lastSync});

  @override
  Widget build(BuildContext context) {
    final lastSyncText = lastSync != null ? 'Última sync: ${_formatTime(lastSync!)}' : 'Nunca sincronizado';

    return CupertinoListTile(
      leading: const Icon(CupertinoIcons.person_circle_fill, size: 40, color: CupertinoColors.activeBlue),
      title: Text(email),
      subtitle: Text(lastSyncText),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSyncing)
            const CupertinoActivityIndicator()
          else
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onSync,
              child: const Icon(CupertinoIcons.arrow_2_circlepath),
            ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onLogout,
            child: const Icon(CupertinoIcons.square_arrow_right, color: CupertinoColors.destructiveRed),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inHours < 1) return 'há ${diff.inMinutes}min';
    if (diff.inDays < 1) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}

class _LoginTile extends StatelessWidget {
  final VoidCallback onLogin;

  const _LoginTile({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      leading: const Icon(CupertinoIcons.person_circle, size: 40, color: CupertinoColors.secondaryLabel),
      title: const Text('Entrar no AnkiWeb'),
      subtitle: const Text('Sincronize entre dispositivos'),
      trailing: const CupertinoListTileChevron(),
      onTap: onLogin,
    );
  }
}
