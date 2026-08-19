/// Models for VLC's Lua HTTP interface (`/requests/status.json` and
/// `/requests/playlist.json`).
library;

enum PlaybackState {
  playing,
  paused,
  stopped,
  unknown;

  static PlaybackState parse(String? value) => switch (value) {
        'playing' => PlaybackState.playing,
        'paused' => PlaybackState.paused,
        'stopped' => PlaybackState.stopped,
        _ => PlaybackState.unknown,
      };
}

class VlcStatus {
  const VlcStatus({
    this.state = PlaybackState.unknown,
    this.time = 0,
    this.length = 0,
    this.volume = 0,
    this.position = 0,
    this.rate = 1,
    this.random = false,
    this.loop = false,
    this.repeat = false,
    this.currentPlId = -1,
    this.title,
    this.artist,
    this.nowPlaying,
    this.filename,
  });

  factory VlcStatus.fromJson(Map<String, dynamic> json) {
    final information = json['information'] as Map<String, dynamic>?;
    final category = information?['category'] as Map<String, dynamic>?;
    final meta = category?['meta'] as Map<String, dynamic>?;

    return VlcStatus(
      state: PlaybackState.parse(json['state'] as String?),
      time: _asInt(json['time']),
      length: _asInt(json['length']),
      volume: _asInt(json['volume']),
      position: _asDouble(json['position']),
      rate: _asDouble(json['rate'], fallback: 1),
      random: _asBool(json['random']),
      loop: _asBool(json['loop']),
      repeat: _asBool(json['repeat']),
      currentPlId: _asInt(json['currentplid'], fallback: -1),
      title: _asNonEmptyString(meta?['title']),
      artist: _asNonEmptyString(meta?['artist']),
      nowPlaying: _asNonEmptyString(meta?['now_playing']),
      filename: _asNonEmptyString(meta?['filename']),
    );
  }

  final PlaybackState state;

  /// Elapsed and total time in seconds.
  final int time;
  final int length;

  /// 0–512, where 256 is 100%.
  final int volume;

  /// 0.0–1.0 within the current item.
  final double position;
  final double rate;
  final bool random;
  final bool loop;
  final bool repeat;

  /// Playlist id of the current item, -1 when nothing is loaded.
  final int currentPlId;

  final String? title;
  final String? artist;
  final String? nowPlaying;
  final String? filename;

  String get displayTitle =>
      title ?? nowPlaying ?? filename ?? 'Nothing playing';

  int get volumePercent => (volume * 100 / 256).round();
}

class PlaylistItem {
  const PlaylistItem({
    required this.id,
    required this.name,
    required this.duration,
    required this.uri,
    required this.isCurrent,
  });

  final int id;
  final String name;

  /// Seconds; -1 when unknown.
  final int duration;
  final String uri;
  final bool isCurrent;
}

/// Flattens VLC's playlist tree (nodes with children) into its leaf items.
List<PlaylistItem> parsePlaylist(Map<String, dynamic> root) {
  final items = <PlaylistItem>[];

  void walk(Map<String, dynamic> node) {
    if (node['type'] == 'leaf') {
      items.add(
        PlaylistItem(
          id: _asInt(node['id'], fallback: -1),
          name: node['name'] as String? ?? 'Unknown',
          duration: _asInt(node['duration'], fallback: -1),
          uri: node['uri'] as String? ?? '',
          isCurrent: node['current'] != null,
        ),
      );
      return;
    }
    final children = node['children'];
    if (children is List) {
      for (final child in children) {
        if (child is Map<String, dynamic>) walk(child);
      }
    }
  }

  walk(root);
  return items;
}

int _asInt(Object? value, {int fallback = 0}) => switch (value) {
      num n => n.toInt(),
      String s => int.tryParse(s) ?? fallback,
      _ => fallback,
    };

double _asDouble(Object? value, {double fallback = 0}) => switch (value) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? fallback,
      _ => fallback,
    };

bool _asBool(Object? value) => switch (value) {
      bool b => b,
      num n => n != 0,
      String s => s == 'true' || s == '1',
      _ => false,
    };

String? _asNonEmptyString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
