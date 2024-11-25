#!/bin/sh

# copy mpv autoload file (needed for gallery view)
# Needed directories that don't get created on their own.
mkdir -p /home/"$USER"/{.cache/thumbnails/mpv-gallery,.config/mpd/playlist} # ,.config/abook/, .cache/transmission/,
mpvautoload="$HOME/.config/mpv/scripts/autoload.lua"
cp /usr/share/mpv/scripts/autoload.lua "$mpvautoload"
sed -i "s/images = true,/images = false,/" "$mpvautoload"
sed -i "s/audio = true,/audio = false,/" "$mpvautoload"
