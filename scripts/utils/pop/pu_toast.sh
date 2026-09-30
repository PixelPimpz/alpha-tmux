#!/usr/bin/env bash
[[ -n "$_ALPHA_TOAST_SH" ]] && return 0
_ALPHA_TOAST_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/pop.sh"

DEFMSG="Notice"
DEFDUR=1.5

pu_toast() {
  local msg title duration
  title="${2:-$DEFMSG}"
  msg="${1:-$title}"
  duration="${3:-$DEFDUR}"

  local min max plain msg_w pop_w pop_h
  min=32; max=60
  plain="$( stripper "$msg" )"
  msg_w="${#plain}"
  pop_w="$(( msg_w + 8 ))"
  (( pop_w < min )) && pop_w="$min"
  (( pop_w > max )) && pop_w="$max"
  pop_h=5

  popped "" "$title" "d" "$pop_w" "$pop_h" "$UTILS/pop/pu_toast.sh" pu_toast_view "$msg" "$duration"
  return $?
}

pu_toast_view() {
  local msg duration
  msg="${1:-$DEFMSG}"
  duration="${2:-$DEFDUR}"
  
  ac; cursor off
  
  printf "\033[2;1H"
  center "$msg"
  read -rs -t "$duration" -n 1

  cursor on
  return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  "$@"
fi
