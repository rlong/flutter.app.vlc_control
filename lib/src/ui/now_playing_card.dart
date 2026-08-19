import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../vlc/vlc_models.dart';
import '../vlc/vlc_providers.dart';
import 'format.dart';

class NowPlayingCard extends ConsumerWidget {
  const NowPlayingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vlcStatusProvider);
    final status = async.value ?? const VlcStatus();
    final connected = !async.hasError && async.hasValue;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          children: [
            Text(
              status.displayTitle,
              style: theme.textTheme.titleLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (status.artist != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  status.artist!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 8),
            _SeekBar(status: status, enabled: connected),
            _TransportControls(status: status, enabled: connected),
            _VolumeControl(status: status, enabled: connected),
          ],
        ),
      ),
    );
  }
}

class _SeekBar extends ConsumerStatefulWidget {
  const _SeekBar({required this.status, required this.enabled});

  final VlcStatus status;
  final bool enabled;

  @override
  ConsumerState<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<_SeekBar> {
  double? _dragValue;
  DateTime _holdUntil = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final seekable = widget.enabled && status.length > 0;
    // Keep showing the dragged value briefly after release so the thumb does
    // not snap back while VLC catches up.
    final holding = DateTime.now().isBefore(_holdUntil);
    final value = _dragValue ??
        (holding ? null : status.time.toDouble().clamp(0, status.length)) ??
        status.time.toDouble().clamp(0, status.length);

    return Row(
      children: [
        Text(formatDuration(value.round())),
        Expanded(
          child: Slider(
            value: seekable ? value.toDouble() : 0,
            max: seekable ? status.length.toDouble() : 1,
            onChanged: seekable
                ? (v) => setState(() => _dragValue = v)
                : null,
            onChangeEnd: seekable
                ? (v) {
                    ref.read(vlcControllerProvider).seekTo(v.round());
                    setState(() {
                      _dragValue = null;
                      _holdUntil =
                          DateTime.now().add(const Duration(milliseconds: 1500));
                    });
                  }
                : null,
          ),
        ),
        Text(formatDuration(status.length > 0 ? status.length : -1)),
      ],
    );
  }
}

class _TransportControls extends ConsumerWidget {
  const _TransportControls({required this.status, required this.enabled});

  final VlcStatus status;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(vlcControllerProvider);
    final playing = status.state == PlaybackState.playing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shuffle),
          tooltip: 'Shuffle',
          isSelected: status.random,
          onPressed: enabled ? controller.toggleRandom : null,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous),
          tooltip: 'Previous',
          iconSize: 32,
          onPressed: enabled ? controller.previous : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: IconButton.filled(
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            tooltip: playing ? 'Pause' : 'Play',
            iconSize: 36,
            onPressed: !enabled
                ? null
                : status.state == PlaybackState.stopped
                    ? controller.play
                    : controller.togglePlayPause,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.stop),
          tooltip: 'Stop',
          onPressed: enabled ? controller.stop : null,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next),
          tooltip: 'Next',
          iconSize: 32,
          onPressed: enabled ? controller.next : null,
        ),
        IconButton(
          icon: const Icon(Icons.repeat),
          tooltip: 'Loop playlist',
          isSelected: status.loop,
          onPressed: enabled ? controller.toggleLoop : null,
        ),
        IconButton(
          icon: const Icon(Icons.repeat_one),
          tooltip: 'Repeat current',
          isSelected: status.repeat,
          onPressed: enabled ? controller.toggleRepeat : null,
        ),
      ],
    );
  }
}

class _VolumeControl extends ConsumerStatefulWidget {
  const _VolumeControl({required this.status, required this.enabled});

  final VlcStatus status;
  final bool enabled;

  @override
  ConsumerState<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends ConsumerState<_VolumeControl> {
  double? _dragValue;

  /// VLC's own UI caps the slider at 125% (320/256).
  static const _max = 320.0;

  @override
  Widget build(BuildContext context) {
    final value =
        (_dragValue ?? widget.status.volume.toDouble()).clamp(0.0, _max);

    return Row(
      children: [
        Icon(
          value == 0 ? Icons.volume_off : Icons.volume_up,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        Expanded(
          child: Slider(
            value: value,
            max: _max,
            onChanged: widget.enabled
                ? (v) => setState(() => _dragValue = v)
                : null,
            onChangeEnd: widget.enabled
                ? (v) {
                    ref.read(vlcControllerProvider).setVolume(v.round());
                    setState(() => _dragValue = null);
                  }
                : null,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${(value * 100 / 256).round()}%',
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
