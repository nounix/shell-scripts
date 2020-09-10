#!/bin/bash

URL="http://46.10.150.243/njoy.mp3"

if pgrep mpv; then pkill mpv; exit; fi

[[ "$1" =~ "http" ]] && URL="$1"
[[ "$(xsel -k -b)" =~ "http" ]] && URL="$(xsel -k -b)"
mpv --really-quiet $URL & \disown && exit
