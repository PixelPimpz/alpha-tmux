#!/usr/bin/env bash
[[ -n "$_ALPHA_POP_SH" ]] && return 0
_ALPHA_POP_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="${PLUGIN_ROOT:-$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )}"
UTILS="${UTILS:-$PLUGIN_ROOT/scripts/utils}"

source "$UTILS/colorizer.sh"

popped() {
  local cmd title size w h  
  cmd="$1"
  title="${2:-alpha-TMUX }"
  size="$3"
  local sbox=("60" "14")
  local mbox=("65" "18")
  local lbox=("85%" "75%")
  case "$size" in 
    lbox|lg|large)
      w="${lbox[0]}"; h="${lbox[1]}" ;;
    mbox|md|medium)
      w="${mbox[0]}"; h="${mbox[1]}" ;;
    *) 
      w="${sbox[0]}"; h="${sbox[1]}" ;;
  esac
  # Launch popup with dynamic border (-S) and background (-s) from colorizer
  tmux display-popup -E -d "$PWD" -w "$w" -h "$h" -b rounded \
    -S "fg=${BORDER_HEX:-default}" \
    -s "bg=${BG_HEX:-default},fg=${TEXT_HEX:-#ebdbb2}" \
    -T "#[align=centre]#[fg=brightwhite,bold] $title " "$cmd"
}
