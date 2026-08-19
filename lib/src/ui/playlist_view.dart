import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../vlc/vlc_providers.dart';
import 'format.dart';

class PlaylistView extends ConsumerWidget {
  const PlaylistView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistProvider);
    final currentPlId =
        ref.watch(vlcStatusProvider).value?.currentPlId ?? -1;
    final controller = ref.read(vlcControllerProvider);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: switch (playlist) {
        AsyncValue(:final value?) when value.isEmpty => Center(
            child: Text(
              'Playlist is empty — add media in VLC.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        AsyncValue(:final value?) => ListView.builder(
            itemCount: value.length,
            itemBuilder: (context, index) {
              final item = value[index];
              final isCurrent =
                  currentPlId >= 0 ? item.id == currentPlId : item.isCurrent;
              return ListTile(
                dense: true,
                selected: isCurrent,
                leading: Icon(
                  isCurrent ? Icons.play_arrow : Icons.music_note,
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                title: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(formatDuration(item.duration)),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Remove from playlist',
                      onPressed: () => controller.removeItem(item.id),
                    ),
                  ],
                ),
                onTap: () => controller.playItem(item.id),
              );
            },
          ),
        AsyncValue(hasError: true) => const SizedBox.shrink(),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
