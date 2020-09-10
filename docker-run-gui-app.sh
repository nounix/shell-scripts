#!/bin/bash

# TODO: update and move from bashrc here

options=(
    --net host
    --cpuset-cpus 0
    --memory 512mb
    --device /dev/snd
    --device /dev/dri
    -e DISPLAY=unix$DISPLAY
    -v /tmp/.X11-unix:/tmp/.X11-unix
    -v /dev/shm:/dev/shm
    -v /run/dbus/:/run/dbus/:ro
    -v /etc/localtime:/etc/localtime:ro
)

# $1 = image , $2 = entrypoint
docker run -it "${options[@]}" $1 $2
