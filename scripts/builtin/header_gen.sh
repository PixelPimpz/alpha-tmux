#!/usr/bin/env bash
##------------------------------------------------------
# HEADER_GEN  generator responsible for taking bitmap
# banner art and converting it to braille art, drawing 
# and providing a tag-line
##------------------------------------------------------
IMAGE="$PLUGIN_ROOT/img/tmux_fp-outline.png"
TAGLINE="$( printf "Welcome to %s, %s! | %s" "$(tmux -V)" "$USER" "$(date "+%A, %b %d %Y")" )"
header_gen() {
  while read -r line; do
    center "$line" "$COLOR_HEADER"
  done <<< "$(ascii-image-converter -b -W 64 "$IMAGE" )"
  while read -r line; do
    center "$line" "$COLOR_TAGLINE"
  done <<< "$TAGLINE"
}
