// Minimal proxy for VLC's Lua HTTP interface.
//
// VLC's HTTP interface sends no CORS headers, so a browser app served from a
// different origin cannot call it directly. This proxy:
//   * forwards /requests/* to VLC, adding CORS headers to the response;
//   * injects the VLC password server-side so it never lives in the browser;
//   * optionally serves the built web app (--web build/web) so the app and
//     the API share one origin and CORS never comes into play.
//
// Usage:
//   dart run tool/vlc_proxy.dart --vlc http://127.0.0.1:8080 --password secret \
//       [--port 8888] [--web build/web]

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final opts = _Options.parse(args);
  final client = HttpClient();
  final server = await HttpServer.bind(InternetAddress.anyIPv4, opts.port);

  stdout.writeln('Proxying http://localhost:${opts.port}/requests/* '
      '-> ${opts.vlc}/requests/*');
  if (opts.webRoot != null) {
    stdout.writeln('Serving web app from ${opts.webRoot} '
        'at http://localhost:${opts.port}/');
  }

  await for (final request in server) {
    unawaited(_handle(request, client, opts).catchError((Object error) {
      stderr.writeln('Error handling ${request.uri}: $error');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.close();
      } catch (_) {}
    }));
  }
}

class _Options {
  _Options({required this.vlc, required this.password, required this.port,
      this.webRoot});

  final Uri vlc;
  final String password;
  final int port;
  final String? webRoot;

  static _Options parse(List<String> args) {
    String? vlc;
    var password = '';
    var port = 8888;
    String? webRoot;
    for (var i = 0; i < args.length; i++) {
      String next() {
        if (i + 1 >= args.length) _usage('missing value for ${args[i]}');
        return args[++i];
      }

      switch (args[i]) {
        case '--vlc':
          vlc = next();
        case '--password':
          password = next();
        case '--port':
          port = int.tryParse(next()) ?? _usage('invalid --port');
        case '--web':
          webRoot = next();
        case '--help' || '-h':
          _usage();
        default:
          _usage('unknown argument ${args[i]}');
      }
    }
    if (vlc == null) _usage('--vlc is required');
    return _Options(
      vlc: Uri.parse(vlc),
      password: password,
      port: port,
      webRoot: webRoot,
    );
  }

  static Never _usage([String? error]) {
    if (error != null) stderr.writeln('Error: $error\n');
    stderr.writeln(
        'Usage: dart run tool/vlc_proxy.dart --vlc http://127.0.0.1:8080 '
        '--password secret [--port 8888] [--web build/web]');
    exit(error == null ? 0 : 64);
  }
}

Future<void> _handle(
  HttpRequest request,
  HttpClient client,
  _Options opts,
) async {
  final response = request.response;
  response.headers
    ..set('access-control-allow-origin', '*')
    ..set('access-control-allow-methods', 'GET, OPTIONS')
    ..set('access-control-allow-headers', 'authorization, content-type');

  if (request.method == 'OPTIONS') {
    response.statusCode = HttpStatus.noContent;
    await response.close();
    return;
  }

  if (request.uri.path.startsWith('/requests/')) {
    await _proxy(request, client, opts);
    return;
  }

  final webRoot = opts.webRoot;
  if (webRoot != null) {
    await _serveStatic(request, webRoot);
    return;
  }

  response.statusCode = HttpStatus.notFound;
  await response.close();
}

Future<void> _proxy(
  HttpRequest request,
  HttpClient client,
  _Options opts,
) async {
  final target = opts.vlc.replace(
    path: request.uri.path,
    query: request.uri.hasQuery ? request.uri.query : null,
  );
  final upstream = await client.getUrl(target);
  if (opts.password.isNotEmpty) {
    upstream.headers.set('authorization',
        'Basic ${base64Encode(utf8.encode(':${opts.password}'))}');
  } else {
    final auth = request.headers.value('authorization');
    if (auth != null) upstream.headers.set('authorization', auth);
  }
  final upstreamResponse = await upstream.close();

  final response = request.response;
  response.statusCode = upstreamResponse.statusCode;
  final contentType = upstreamResponse.headers.contentType;
  if (contentType != null) response.headers.contentType = contentType;
  await upstreamResponse.pipe(response);
}

const _contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.woff2': 'font/woff2',
};

Future<void> _serveStatic(HttpRequest request, String webRoot) async {
  final root = Directory(webRoot).absolute.path;
  var path = Uri.decodeComponent(request.uri.path);
  if (path.endsWith('/')) path = '${path}index.html';

  var file = File('$root$path');
  if (!file.absolute.path.startsWith(root) || !file.existsSync()) {
    // Single-page app fallback.
    file = File('$root/index.html');
  }

  final response = request.response;
  if (!file.existsSync()) {
    response.statusCode = HttpStatus.notFound;
    await response.close();
    return;
  }

  final dot = file.path.lastIndexOf('.');
  final extension = dot >= 0 ? file.path.substring(dot) : '';
  final contentType = _contentTypes[extension];
  if (contentType != null) {
    response.headers.set('content-type', contentType);
  }
  await file.openRead().pipe(response);
}
