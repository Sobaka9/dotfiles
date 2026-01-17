#!/bin/sh

# FOR PC SETUP
xrandr --output DP-2 --mode 2560x1440 --scale 1x1 --pos 1920x0 --rate 244 --primary 
xrandr --output DP-4 --mode 1920x1080 --scale 1x1 --pos 0x0 --rate 144
xset -dpms
xrdb -merge ~/.Xresources

feh --bg-scale ~/Pictures/wallpapers/walls/flower-field-painting.png && \
dwm & \
slstatus & \
picom
