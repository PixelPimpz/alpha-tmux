#!/usr/bin/env bash
#
PLUGIN_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IMAGE="$PLUGIN_ROOT/img/tmux_fp-outline.png"
TAGLINE="$( printf "Welcome to %s, %s! | %s" "$(tmux -V)" "$USER" "$(date "+%A, %b %d %Y")" )"

center() {
  local row roww termw pad
  row="$1"
  roww="${#row}"
  termw="$(tput cols)"
  pad=$(( ( termw - roww ) / 2 ))
  printf "%*s%s\n" "$pad" "" "$row"
}
#
banner_gen() {
  while read -r line; do
    center "$line"
  done <<< "$(ascii-image-converter -b -W 64 "$IMAGE" )"
  while read -r line; do
    center "$line"
  done <<< "$TAGLINE"
}
#
menu_gen() {
  echo "teh menu, lolduh"
}
#
#recents() {}
#
footer_gen() {
  echo "I hope this satisfies the foot-people"
}
#
main() {
  banner_gen
}
main
