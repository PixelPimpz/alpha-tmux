#!/usr/bin/env bash
[[ -n "$_ALPHA_PU_CONFIRM_SH" ]] && return 0
_ALPHA_PU_CONFIRM_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/pop.sh"
source "$UTILS/pop/pu_buttons.sh"

pu_confirm() {
  local msg="${1:-Are you sure?}"
  local title="${2:-Confirm}"
  local def_idx="${3:-0}"
  local labels=("${@:4}")
  (( ${#labels[@]} == 0 )) && labels=("Yes" "No")
  local plain len w h
  plain="$(stripper "$msg")"
  len="${#plain}"
  w=$(( len + 8 ))
  (( w < 38 )) && w=38
  h=8

  popped "" "$title" "d" "$w" "$h" "$UTILS/pop/pu_confirm.sh" pu_confirm_view "$msg" "$def_idx" "${labels[@]}"
  return $?
}

pu_confirm_view() {
  local msg="${1:-Are you sure?}"
  local def_idx="${2:-0}"
  local labels=("${@:3}")
  (( ${#labels[@]} == 0 )) && labels=("Yes" "No")

  ac
  printf "\033[3;1H"
  center "$msg"
  pu_buttons "$def_idx" "${labels[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  "$@"
fi
