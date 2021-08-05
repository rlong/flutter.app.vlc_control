




Setup
=====

```
export VLC_BASE_URL=http://127.0.0.1:8080
export VLC_USER_PASS=:vlccontrol
```

browse
======

```
curl -is -u $VLC_USER_PASS $VLC_BASE_URL/requests/browse.json?uri=file:///
```


playlist
========

```
curl -is -u $VLC_USER_PASS $VLC_BASE_URL/requests/playlist.json
```


status
======


```
curl -is -u $VLC_USER_PASS $VLC_BASE_URL/requests/status.json
```


pl_play
-------


```
curl -is -u $VLC_USER_PASS "$VLC_BASE_URL/requests/status.json?command=pl_play&id=4"
```

volume
------


```
curl -is -u $VLC_USER_PASS "$VLC_BASE_URL/requests/status.json?command=volume&val=0"
```

