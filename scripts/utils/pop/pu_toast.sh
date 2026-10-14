#!/usr/bin/env bash
[[ -n "$_ALPHA_TOAST_SH" ]] && return 0
_ALPHA_TOAST_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
# shellcheck source=/dev/null
source "$UTILS/pop.sh"

DEFMSG="Notice"
DEFDUR=1.5

pu_toast() {
  local OPTIND opt title="$DEFMSG" duration="$DEFDUR" sub=""
  while getopts ":t:d:s:" opt; do
    case "$opt" in
      t) title="$OPTARG" ;;
      d) duration="$OPTARG" ;;
      s) sub="$OPTARG" ;;
      *) ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  local msg="${1:-$title}"
  [[ -n "$2" && "$title" == "$DEFMSG" ]] && title="$2"
  [[ -n "$3" && "$duration" == "$DEFDUR" ]] && duration="$3"

  local pop_w pop_h
  read -r pop_w pop_h < <(popsizer "$msg" "$sub") 

  popped "" "$title" "d" "$pop_w" "$pop_h" "$UTILS/pop/pu_toast.sh" pu_toast_view "$msg" "$duration" "$sub"
  return $?
}

pu_toast_view() {
  local msg duration sub
  msg="${1:-$DEFMSG}"
  duration="${2:-$DEFDUR}"
  sub="$3"
  
  ac; cursor off
  
  printf "\033[2;1H"
  center "$msg"
  if [[ -n "$sub" ]]; then
    printf "\033[3;1H"
    center "$sub" "$MUTEDC"
  fi
  read -rs -t "$duration" -n 1

  cursor on
  return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  "$@"
fi
