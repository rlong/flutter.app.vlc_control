import 'dart:convert';

import 'package:http/http.dart' as http;

import 'vlc_models.dart';

class VlcApiException implements Exception {
  const VlcApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thin client for VLC's Lua HTTP interface.
///
/// All commands go through `/requests/status.json?command=...`, which
/// conveniently returns the updated status in the same response.
class VlcClient {
  VlcClient({required this.baseUri, this.password = '', http.Client? client})
      : _http = client ?? http.Client();

  final Uri baseUri;
  final String password;
  final http.Client _http;

  static const _timeout = Duration(seconds: 4);

  Map<String, String> get _headers => password.isEmpty
      ? const {}
      : {'authorization': 'Basic ${base64Encode(utf8.encode(':$password'))}'};

  Future<VlcStatus> status() async =>
      VlcStatus.fromJson(await _getJson('requests/status.json'));

  Future<VlcStatus> command(
    String command, [
    Map<String, String> args = const {},
  ]) async {
    final json = await _getJson('requests/status.json', {
      'command': command,
      ...args,
    });
    return VlcStatus.fromJson(json);
  }

  Future<List<PlaylistItem>> playlist() async =>
      parsePlaylist(await _getJson('requests/playlist.json'));

  Future<Map<String, dynamic>> _getJson(
    String path, [
    Map<String, String>? query,
  ]) async {
    var uri = baseUri.resolve(path);
    if (query != null) {
      uri = uri.replace(queryParameters: query);
    }
    final response =
        await _http.get(uri, headers: _headers).timeout(_timeout);
    if (response.statusCode == 401) {
      throw const VlcApiException(
        'Authentication failed — check the VLC password.',
      );
    }
    if (response.statusCode != 200) {
      throw VlcApiException('VLC returned HTTP ${response.statusCode}.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
