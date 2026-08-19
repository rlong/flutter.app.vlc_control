# VLC Remote (vlc_control)

A Flutter **web** app that remote-controls VLC through its Lua HTTP interface:
play/pause/stop, previous/next, seeking, volume, shuffle/loop/repeat, and
playlist browsing (click to play, remove items).

Stack: Flutter (Material 3), Riverpod 3 for state, `http` for the API,
`shared_preferences` for persisted connection settings.

## 1. Enable VLC's HTTP interface

Either from the GUI — *Tools → Preferences → (Show settings: All) →
Interface → Main interfaces*: check **Web**, then under *Main interfaces →
Lua* set a **Lua HTTP password** — or start VLC from the command line:

```sh
vlc --extraintf http --http-password secret --http-port 8080
```

Sanity-check it with:

```sh
curl -s -u ":secret" http://127.0.0.1:8080/requests/status.json | head -c 200
```

## 2. The CORS catch (read this once)

VLC's HTTP interface sends **no CORS headers**, so a browser app served from
any other origin is blocked from calling it directly. `tool/vlc_proxy.dart`
solves this: it forwards `/requests/*` to VLC, adds CORS headers, injects the
password server-side, and can also serve the built app so everything is one
origin.

```sh
dart run tool/vlc_proxy.dart --vlc http://127.0.0.1:8080 --password secret --port 8888
```

## 3. Develop

```sh
export PATH="$PATH:/opt/flutter/bin"
flutter run -d web-server --web-port 5173   # or: -d chrome
```

Run the proxy (step 2), open the app, click the ⚙ settings icon and set
**Server URL** to `http://localhost:8888` (leave the password empty — the
proxy injects it).

## 4. Build & serve for real use

```sh
flutter build web
dart run tool/vlc_proxy.dart --vlc http://127.0.0.1:8080 --password secret \
    --port 8888 --web build/web
```

Then browse to `http://<machine>:8888` from anything on your network. In this
mode leave **Server URL** empty in the app settings — the app talks to its own
origin and the proxy does the rest.

## Project layout

```
lib/
  main.dart                       app + theme + bootstrap
  src/
    settings/connection_settings.dart   persisted server URL/password (Riverpod Notifier)
    vlc/vlc_models.dart           status/playlist models + JSON parsing
    vlc/vlc_client.dart           thin HTTP client for /requests/*
    vlc/vlc_providers.dart        status poller (1s), playlist poller (5s), command controller
    ui/                           home page, now-playing card, playlist, settings dialog
tool/vlc_proxy.dart               CORS/auth proxy + static server for build/web
```

## Tests

```sh
flutter test
```
