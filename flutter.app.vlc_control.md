

Files, Folders, Sub-Projects
============================

Files
-----

- Logs: 
  - [main.md](docs/logs.claude/main.md)

- docs:
  - [curl.md](docs/curl.md)


Bookmarks
=========


Project Bookmarks
-----------------

Internet
--------



Session Setup
=============

Simple Shell
------------


```bash
tmux new-session -s vlc_control_bash
tmux new-session -s vlc_control_claude_code
```


```
export PROJECTS_ROOT=~/Projects/flutter.app.vlc_control/Projects
export PATH=$PATH:~/Projects/comshep/.venv/bin
export PATH=$PATH:/opt/flutter/bin
export _PROJECT_ID=flutter.app.vlc_control
export _HOME=$PROJECTS_ROOT/$_PROJECT_ID
export _HOME="$_HOME${_AGENT_ID:+.$_AGENT_ID}"
export PS1="\[\e[1;37m\]\u@\h /\W\[\e[1;36m\]\$(__git_branch)\[\e[1;37m\] \$\[\e[0m\]"
cd $_HOME
```

Agentic
-------


```bash
export _AGENT_ID=vc1
tmux new-session -s "$_AGENT_ID"_bash -e _AGENT_ID=$_AGENT_ID
tmux new-session -s "$_AGENT_ID"_claude_code -e _AGENT_ID=$_AGENT_ID
```


... run the script above


Debug/Development
=================


IntelliJ IDEA Projects
----------------------

```
~/Projects/flutter.app.vlc_control/Projects/flutter.app.vlc_control
```


Serve
-----

### Serve: Start VLC

```bash
vlc --extraintf http --http-password secret --http-port 8080
```


### Serve: Start VLC Control

```bash
dart run tool/vlc_proxy.dart --vlc http://127.0.0.1:8080 --password secret --port 8888 --web build/web
```

- http://localhost:8888/


