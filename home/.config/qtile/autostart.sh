#!/bin/sh

autorandr -c

hsetroot -solid "#696969"

picom --vsync --shadow --backend glx & 

nm-applet &
volumeicon &
ulauncher --no-window-shadow &
cbatticon &
