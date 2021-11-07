#!/bin/sh

hsetroot -solid "#696969"

picom --vsync --shadow \
    --backend xrender --xrender-sync-fence &

nm-applet &
volumeicon &
ulauncher --no-window-shadow &
cbatticon &
