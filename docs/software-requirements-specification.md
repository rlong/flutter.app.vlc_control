# Software Requirements Specification — VLC Remote (`vlc_control`)

| | |
|---|---|
| **Version** | 0.1 |
| **Date** | 2026-08-19 |
| **Status** | Draft — describes the system as initially implemented |
| **Author** | rich@ardlong.com (drafted with Claude Code) |

---

## 1. Introduction

### 1.1 Purpose

This document specifies the requirements for **VLC Remote**, a browser-based
remote control for the VLC media player. It is the reference for what the
application must do, the interfaces it depends on, and the constraints it
operates under. Requirement IDs (`FR-*`, `NFR-*`, `IF-*`, `C-*`) are stable and
may be referenced from commits, issues, and tests.

### 1.2 Scope

VLC Remote lets a user control a running VLC instance from any modern web
browser on the same network: transport control (play, pause, stop, previous,
next), seeking, volume, playback modes (shuffle, loop, repeat), and playlist
browsing/selection. It communicates exclusively with VLC's built-in Lua HTTP
interface; it does not play media itself.

**In scope:** a Flutter web application, and a small companion proxy
(`tool/vlc_proxy.dart`) required to bridge the browser to VLC (see C-2).

**Out of scope (this version):** native iOS/Android/desktop builds, media
library browsing (`/requests/browse.json`), adding new media to the playlist,
multiple simultaneous VLC targets, streaming or transcoding, user accounts.

### 1.3 Definitions and abbreviations

| Term | Meaning |
|---|---|
| **VLC HTTP interface** | VLC's built-in Lua web interface (`--extraintf http`), serving `/requests/*.json` endpoints protected by HTTP Basic auth (empty username, `--http-password`). |
| **Proxy** | `tool/vlc_proxy.dart`; forwards `/requests/*` to VLC, adds CORS headers, injects credentials, optionally serves the built web app. |
| **Same-origin mode** | Deployment where the proxy serves the web app and the API from one origin, eliminating CORS entirely. |
| **CORS** | Cross-Origin Resource Sharing; browser policy governing cross-origin HTTP requests. |
| **SRS** | This document. |

### 1.4 References

- VLC Lua HTTP interface: `share/lua/http/requests/README.txt` in the VLC source tree
- Project README: `../README.md`
- IEEE 830 (structure loosely followed)

---

## 2. Overall description

### 2.1 Product perspective

The system has three cooperating parts:

```
Browser (Flutter web app)  ──HTTP──▶  Proxy (dart:io)  ──HTTP──▶  VLC Lua HTTP interface
        UI + state                     CORS + auth                    playback engine
```

The app is a pure client: all playback state lives in VLC and is re-fetched by
polling. The app holds only connection settings and transient UI state.

### 2.2 Users

A single class of user: a person on the local network who wants to control a
VLC instance running elsewhere (media PC, HTPC, another room). No roles,
no per-user data.

### 2.3 Operating environment

- Any modern evergreen browser (Chromium, Firefox, Safari) on desktop or mobile.
- VLC 3.x+ with the Lua HTTP interface enabled and a password set.
- The proxy runs wherever Dart is available — typically the machine running VLC.

### 2.4 Assumptions and dependencies

- The user can enable VLC's web interface and set `--http-password`.
- App, proxy, and VLC are reachable over a trusted local network (see NFR-7).
- VLC's status/playlist JSON schema remains as shipped in VLC 3.x/4.x.

---

## 3. External interface requirements

**IF-1 — VLC status endpoint.** The system SHALL read playback state from
`GET /requests/status.json`, parsing at minimum: `state`, `time`, `length`,
`position`, `volume`, `rate`, `random`, `loop`, `repeat`, `currentplid`, and
`information.category.meta` (`title`, `artist`, `now_playing`, `filename`).
Parsing SHALL tolerate missing fields and numeric/boolean type variance across
VLC versions.

**IF-2 — VLC command endpoint.** The system SHALL issue commands as
`GET /requests/status.json?command=<cmd>[&<args>]` and SHALL apply the status
returned in the command response immediately (without waiting for the next
poll). Commands used: `pl_pause`, `pl_play` (with optional `id`), `pl_stop`,
`pl_next`, `pl_previous`, `seek` (`val` in seconds), `volume` (`val` 0–512),
`pl_random`, `pl_loop`, `pl_repeat`, `pl_delete` (`id`).

**IF-3 — VLC playlist endpoint.** The system SHALL read the playlist from
`GET /requests/playlist.json` and flatten VLC's node/leaf tree into an ordered
list of items (id, name, duration, uri, current flag).

**IF-4 — Authentication.** When a password is configured in the app, requests
SHALL carry HTTP Basic credentials with an empty username. When the password is
empty, no `Authorization` header is sent (the proxy injects credentials in that
deployment).

**IF-5 — Proxy.** The proxy SHALL (a) forward `/requests/*` verbatim (path and
query) to the configured VLC base URL; (b) respond to CORS preflight
(`OPTIONS`) with 204 and emit `Access-Control-Allow-Origin: *` on all
responses; (c) inject `Authorization` from its `--password` flag, else pass
through the client's header; (d) when `--web <dir>` is given, serve that
directory as a static site with `index.html` fallback; (e) report upstream
failure as HTTP 500 without crashing.

---

## 4. Functional requirements

Priorities: **M** = must, **S** = should, **C** = could.
Status reflects version 0.1.

| ID | Requirement | Pri | Status |
|---|---|---|---|
| FR-1 | Display the current item's title (falling back to now-playing text, then filename, then a "Nothing playing" placeholder) and artist when available. | M | Implemented |
| FR-2 | Display playback state (playing / paused / stopped) and elapsed/total time in `m:ss` / `h:mm:ss` form. | M | Implemented |
| FR-3 | Poll VLC status at a fixed interval of 1 s while the app is open. | M | Implemented |
| FR-4 | Provide play/pause toggle, stop, previous, and next controls. From the stopped state the play control SHALL start playback (`pl_play`). | M | Implemented |
| FR-5 | Provide a seek bar scaled to item length; releasing it SHALL seek VLC to the chosen second. While dragging (and briefly after release) the bar SHALL NOT snap back to polled values. | M | Implemented |
| FR-6 | Provide a volume slider over 0–125 % (VLC 0–320 raw, 256 = 100 %) showing the current percentage; releasing it SHALL set VLC's volume. | M | Implemented |
| FR-7 | Provide toggles for shuffle (`pl_random`), loop playlist (`pl_loop`), and repeat current (`pl_repeat`), each reflecting VLC's reported state. | S | Implemented |
| FR-8 | Display the playlist (flattened, in VLC order) with each item's name and duration, refreshed at most every 5 s and immediately after playlist-mutating actions. | M | Implemented |
| FR-9 | Visually mark the currently playing playlist item, preferring the live status `currentplid` over the (possibly staler) playlist snapshot. | S | Implemented |
| FR-10 | Start playback of a playlist item when the user activates it (`pl_play&id=`). | M | Implemented |
| FR-11 | Allow removing an item from the playlist (`pl_delete&id=`). | S | Implemented |
| FR-12 | Provide a settings surface for server URL and password; persist both across browser sessions. An empty server URL SHALL mean "same origin as the app". | M | Implemented |
| FR-13 | When VLC is unreachable or authentication fails, show a non-blocking banner with the error and a shortcut to settings; disable transport controls; recover automatically on the next successful poll. | M | Implemented |
| FR-14 | Indicate connection state (connecting / connected / disconnected) persistently in the app bar. | S | Implemented |
| FR-15 | Add media to the playlist by URL/MRL (`in_enqueue` / `in_play`). | C | Not implemented |
| FR-16 | Browse the host filesystem via `/requests/browse.json` to queue media. | C | Not implemented |
| FR-17 | Control playback rate and audio/subtitle track selection. | C | Not implemented |
| FR-18 | Support fullscreen toggle (`fullscreen`) on the VLC instance. | C | Not implemented |

---

## 5. Non-functional requirements

**NFR-1 — Perceived latency.** UI feedback for a user command SHALL reflect
VLC's returned state within one command round-trip (no waiting for the next
poll tick). Background staleness SHALL never exceed one poll interval (1 s)
plus network time.

**NFR-2 — Request budget.** Steady-state load SHALL NOT exceed ~1.2 requests/s
per open client (status 1 Hz + playlist 0.2 Hz).

**NFR-3 — Resilience.** A failed poll SHALL NOT terminate polling; transient
errors SHALL self-heal with no user action. Command failures SHALL NOT crash
or wedge the UI (connectivity is surfaced by the status poller).

**NFR-4 — Responsive layout.** The UI SHALL be usable from phone-width
(~360 px) to desktop; content is constrained to a readable column (≤ 680 px).

**NFR-5 — Theming.** The app SHALL follow the OS light/dark preference using
Material 3 color schemes derived from a single seed color.

**NFR-6 — Timeouts.** Every VLC request SHALL time out (4 s) rather than hang.

**NFR-7 — Security posture.** The system targets trusted LANs. The password is
stored in browser `localStorage` (via `shared_preferences`) and sent as Basic
auth; the proxy's `--password` flag keeps the credential out of the browser
entirely and is the recommended deployment. The system SHALL NOT be exposed to
the public internet without an external TLS/auth layer; this is documentation,
not enforced by software.

**NFR-8 — Code quality.** The codebase SHALL pass `flutter analyze` with zero
issues and keep the widget test suite green. State management follows idiomatic
Riverpod (Notifier/Provider); models are immutable.

**NFR-9 — Compatibility.** No APIs outside Flutter's stable web support may be
used; the proxy uses only the Dart SDK (`dart:io`), no packages.

---

## 6. Design constraints

**C-1 — Web-only target.** Only the Flutter *web* platform is built. No
platform folders other than `web/` exist; nothing may depend on `dart:io` in
`lib/`.

**C-2 — CORS.** VLC's HTTP interface emits no CORS headers, so browsers block
direct cross-origin calls to it. Consequently every cross-origin deployment
REQUIRES the proxy (IF-5); same-origin mode (proxy serves `build/web`) is the
recommended deployment. This constraint is inherent to VLC and cannot be fixed
app-side.

**C-3 — Polling, not push.** VLC's Lua interface offers no event/WebSocket
channel; state synchronization is polling-based by necessity (FR-3, NFR-2).

**C-4 — VLC volume model.** Volume is an integer where 256 = 100 %; the UI
caps at 320 (125 %), matching VLC's own controls.

---

## 7. Acceptance criteria (v0.1)

1. With VLC running (`vlc --extraintf http --http-password secret`) and the
   proxy in same-origin mode, opening the app shows current status within 2 s.
2. Each control in FR-4–FR-7 changes VLC's behavior and the UI reflects it
   without a page reload.
3. Clicking a playlist item starts it; removing an item deletes it from VLC's
   playlist; the current item is highlighted.
4. Stopping VLC mid-session raises the disconnected banner; restarting VLC
   clears it without user action.
5. `flutter analyze` reports no issues; `flutter test` passes;
   `flutter build web` succeeds.

---

## 8. Future considerations

Candidate requirements for later versions, intentionally deferred: FR-15–FR-18
(enqueue by URL, file browsing, rate/track control, fullscreen), equalizer
control, multiple VLC profiles with quick switching, PWA install polish
(offline shell, icons), and native desktop/mobile targets.
