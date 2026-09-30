#!/usr/bin/env bash
[[ -n "$_ALPHA_POP_SH" ]] && return 0
_ALPHA_POP_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/colorizer.sh"
source "$UTILS/navigator.sh"
source "$UTILS/formats.sh"

popped() {
  local cmd title size w h dw dh
  cmd="$1"
  title="${2:-alpha-TMUX}"
  size="$3"
  dw="$4"; dh="$5"
  local sbox=("60" "14")
  local mbox=("65" "18")
  local lbox=("85%" "75%")
  local dbox=("${dw}" "${dh}")
  
  case "$size" in 
    lbox|l|large)
      w="${lbox[0]}"; h="${lbox[1]}" ;;
    mbox|m|medium)
      w="${mbox[0]}"; h="${mbox[1]}" ;;
    sbox|s|small)
      w="${sbox[0]}"; h="${sbox[1]}" ;;
    dbox|d|dynamic)
      w="${dbox[0]}"; h="${dbox[1]}" ;;
    *)
      w="${sbox[0]}"; h="${sbox[1]}" ;;
  esac

  shift 5 2>/dev/null || shift $#
  if (( $# > 0 )); then
    tmux display-popup -E -d "$PWD" -w "$w" -h "$h" -b rounded \
      -S "fg=${BORDER_HEX:-default}" \
      -s "bg=${BG_HEX:-default},fg=${TEXT_HEX:-#ebdbb2}" \
      -T "#[align=centre]#[fg=brightwhite,bold] $title " "$@"
  else
    tmux display-popup -E -d "$PWD" -w "$w" -h "$h" -b rounded \
      -S "fg=${BORDER_HEX:-default}" \
      -s "bg=${BG_HEX:-default},fg=${TEXT_HEX:-#ebdbb2}" \
      -T "#[align=centre]#[fg=brightwhite,bold] $title " "$cmd"
  fi
}

## Sub-modules
source "$UTILS/pop/pu_buttons.sh"
source "$UTILS/pop/pu_toast.sh"
source "$UTILS/pop/pu_confirm.sh"
source "$UTILS/pop/pu_input.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  "$@"
fi
