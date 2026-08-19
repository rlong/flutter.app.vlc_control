import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../vlc/vlc_providers.dart';
import 'now_playing_card.dart';
import 'playlist_view.dart';
import 'settings_dialog.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(vlcStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VLC Remote'),
        actions: [
          _ConnectionIndicator(status: status),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Connection settings',
            onPressed: () => showSettingsDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (status.hasError) _DisconnectedBanner(status: status),
                const NowPlayingCard(),
                const SizedBox(height: 12),
                const Expanded(child: PlaylistView()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.status});

  final AsyncValue<Object?> status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (status.isLoading && !status.hasValue) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        status.hasError ? Icons.cloud_off : Icons.cloud_done,
        color: status.hasError ? colors.error : colors.primary,
      ),
    );
  }
}

class _DisconnectedBanner extends ConsumerWidget {
  const _DisconnectedBanner({required this.status});

  final AsyncValue<Object?> status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cannot reach VLC: ${status.error}',
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: () => showSettingsDialog(context),
              child: const Text('Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
