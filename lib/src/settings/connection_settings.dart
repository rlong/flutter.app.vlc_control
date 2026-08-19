import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

/// How to reach the VLC HTTP interface (or a proxy in front of it).
class ConnectionSettings {
  const ConnectionSettings({this.serverUrl = '', this.password = ''});

  /// Base URL of the VLC HTTP interface, e.g. `http://192.168.1.10:8080`.
  /// Empty means "same origin as this web app" — the mode used when the app
  /// is served through `tool/vlc_proxy.dart`.
  final String serverUrl;

  /// VLC's `--http-password`. Leave empty when a proxy injects it.
  final String password;

  Uri get baseUri => serverUrl.isEmpty ? Uri.base : Uri.parse(serverUrl);

  ConnectionSettings copyWith({String? serverUrl, String? password}) {
    return ConnectionSettings(
      serverUrl: serverUrl ?? this.serverUrl,
      password: password ?? this.password,
    );
  }
}

class SettingsNotifier extends Notifier<ConnectionSettings> {
  static const _urlKey = 'server_url';
  static const _passwordKey = 'password';

  @override
  ConnectionSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ConnectionSettings(
      serverUrl: prefs.getString(_urlKey) ?? '',
      password: prefs.getString(_passwordKey) ?? '',
    );
  }

  Future<void> save(ConnectionSettings settings) async {
    state = settings;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_urlKey, settings.serverUrl);
    await prefs.setString(_passwordKey, settings.password);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, ConnectionSettings>(
  SettingsNotifier.new,
);
