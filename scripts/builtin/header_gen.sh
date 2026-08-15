#!/usr/bin/env bash
[[ -n "$_ALPHA_HEADER_GEN_SH" ]] && return 0
_ALPHA_HEADER_GEN_SH=1

source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

##------------------------------------------------------
# HEADER_GEN  generator responsible for taking bitmap
# banner art and converting it to braille art, drawing 
# and providing a tag-line
##------------------------------------------------------
IMAGE="$PLUGIN_ROOT/img/tmux_fp-outline.png"
TAGLINE="$( printf "Welcome to %s, %s! | %s" "$(tmux -V)" "$USER" "$(date "+%A, %b %d %Y")" )"
header_gen() {
  while read -r line; do
    center "$line" "$HEADERC"
  done <<< "$(ascii-image-converter -b -W 64 "$IMAGE" )"
  while read -r line; do
    center "$line" "$TAGLINEC"
  done <<< "$TAGLINE"
}
