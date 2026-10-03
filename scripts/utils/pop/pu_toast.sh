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

  local min max plain_msg plain_sub msg_w sub_w max_w pop_w pop_h
  min=32; max=80
  plain_msg="$( stripper "$msg" )"
  msg_w="${#plain_msg}"
  plain_sub="$( stripper "$sub" )"
  sub_w="${#plain_msg}"
  pop_w="$(( msg_w + 8 ))"

  max_w=$(( msg_w > sub_w ? msg_w : sub_w ))
  pop_w="$(( max_w + 8 ))"
  (( pop_w < min )) && pop_w="$min"
  (( pop_w > max )) && pop_w="$max"
  
  pop_h=5
  [[ -n "$sub" ]] && pop_h=6
  popped "" "$title" "d" "$pop_w" "$pop_h" "$UTILS/pop/pu_toast.sh" pu_toast_view "$msg" "$duration" "$sub"
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
