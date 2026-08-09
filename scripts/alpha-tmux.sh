#!/usr/bin/env bash
#
PLUGIN_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
IMAGE="$PLUGIN_ROOT/img/tmux_fp-outline.png"
TAGLINE="$( printf "Welcome to %s, %s! | %s" "$(tmux -V)" "$USER" "$(date "+%A, %b %d %Y")" )"
#
# ----- Helper functions
center() {
  local row roww termw pad
  row="$1"
  roww="${#row}"
  termw="$(tput cols)"
  pad=$(( ( termw - roww ) / 2 ))
  printf "%*s%s\n" "$pad" "" "$row"
}
#
is_session() {
  local bool
    if tmux ls >/dev/null 2>&1; then 
      bool="true"
    else bool="false"
  fi
  echo "$bool"
}
# ----- Generator functions 
banner_gen() {
  while read -r line; do
    center "$line"
  done <<< "$(ascii-image-converter -b -W 64 "$IMAGE" )"
  while read -r line; do
    center "$line"
  done <<< "$TAGLINE"
}
#
menu_mockup() {
  while read -r line; do
    center "$line"
  done <<< "$(echo -e "[x] X button1\t[x] X button2\t[x] X button3\t[x] X button4\t[x] X button5\t" | boxes -d ansi)"
}
#
main() {
  banner_gen
  center " "
  menu_mockup
}
main
