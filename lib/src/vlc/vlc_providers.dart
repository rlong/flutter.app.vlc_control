import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/connection_settings.dart';
import 'vlc_client.dart';
import 'vlc_models.dart';

final vlcClientProvider = Provider<VlcClient>((ref) {
  final settings = ref.watch(settingsProvider);
  return VlcClient(baseUri: settings.baseUri, password: settings.password);
});

/// Polls `/requests/status.json` once a second. Commands push their fresh
/// status through [apply] so the UI reacts immediately instead of waiting for
/// the next poll.
class VlcStatusNotifier extends Notifier<AsyncValue<VlcStatus>> {
  @override
  AsyncValue<VlcStatus> build() {
    final client = ref.watch(vlcClientProvider);
    final timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _poll(client),
    );
    ref.onDispose(timer.cancel);
    Future.microtask(() => _poll(client));
    return const AsyncValue.loading();
  }

  Future<void> _poll(VlcClient client) async {
    try {
      final status = await client.status();
      if (!ref.mounted || client != ref.read(vlcClientProvider)) return;
      state = AsyncValue.data(status);
    } catch (error, stackTrace) {
      if (!ref.mounted || client != ref.read(vlcClientProvider)) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void apply(VlcStatus status) => state = AsyncValue.data(status);
}

final vlcStatusProvider =
    NotifierProvider<VlcStatusNotifier, AsyncValue<VlcStatus>>(
  VlcStatusNotifier.new,
);

class PlaylistNotifier extends Notifier<AsyncValue<List<PlaylistItem>>> {
  @override
  AsyncValue<List<PlaylistItem>> build() {
    final client = ref.watch(vlcClientProvider);
    final timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _poll(client),
    );
    ref.onDispose(timer.cancel);
    Future.microtask(() => _poll(client));
    return const AsyncValue.loading();
  }

  Future<void> refresh() => _poll(ref.read(vlcClientProvider));

  Future<void> _poll(VlcClient client) async {
    try {
      final items = await client.playlist();
      if (!ref.mounted || client != ref.read(vlcClientProvider)) return;
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      if (!ref.mounted || client != ref.read(vlcClientProvider)) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final playlistProvider =
    NotifierProvider<PlaylistNotifier, AsyncValue<List<PlaylistItem>>>(
  PlaylistNotifier.new,
);

/// Issues playback commands. Errors are swallowed here because the status
/// poller already surfaces connection problems in the UI.
class VlcController {
  const VlcController(this._ref);

  final Ref _ref;

  Future<void> _command(
    String command, [
    Map<String, String> args = const {},
  ]) async {
    try {
      final status = await _ref.read(vlcClientProvider).command(command, args);
      _ref.read(vlcStatusProvider.notifier).apply(status);
    } on Exception {
      // Ignored: the status poller reports connectivity.
    }
  }

  Future<void> togglePlayPause() => _command('pl_pause');
  Future<void> play() => _command('pl_play');
  Future<void> stop() => _command('pl_stop');
  Future<void> next() => _command('pl_next');
  Future<void> previous() => _command('pl_previous');
  Future<void> seekTo(int seconds) => _command('seek', {'val': '$seconds'});
  Future<void> setVolume(int volume) => _command('volume', {'val': '$volume'});
  Future<void> toggleRandom() => _command('pl_random');
  Future<void> toggleLoop() => _command('pl_loop');
  Future<void> toggleRepeat() => _command('pl_repeat');

  Future<void> playItem(int id) async {
    await _command('pl_play', {'id': '$id'});
    await _ref.read(playlistProvider.notifier).refresh();
  }

  Future<void> removeItem(int id) async {
    await _command('pl_delete', {'id': '$id'});
    await _ref.read(playlistProvider.notifier).refresh();
  }
}

final vlcControllerProvider = Provider<VlcController>(VlcController.new);
