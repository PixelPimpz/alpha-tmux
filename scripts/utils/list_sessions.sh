#!/usr/bin/env bash
[[ -n "$_ALPHA_LIST_SESSIONS_SH" ]] && return 0
_ALPHA_LIST_SESSIONS_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"

PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/colorizer.sh"
source "$UTILS/yqtools.sh"
source "$UTILS/icons.sh"
source "$UTILS/profiler.sh"

BLUEPRINTS_D="$(get_option "blueprints" "${XDG_CONFIG_HOME:-$HOME/.config}/alpha-tmux/blueprints")"
BLUEPRINTS_D="${BLUEPRINTS_D/#\~/$HOME}"
ICO_OPEN="$(get_icon "dot_open")"
ICO_CLOSED="$(get_icon "dot_closed")"
STATE=(
  "${KEYC}${ICO_OPEN}${RESET}"
  "${MUTEDC}${ICO_CLOSED}${RESET}"
  "${SUCCESSC}${ICO_CLOSED}${RESET}"
)

declare -A Sessions

list_sessions() {
  local s created longest=0
  local save_f created filter="all"
  while (( "$#" > 0 )); do
    case "$1" in 
      -s|--saved)   filter="saved";;
      -a|--all)     filter="all";;
      -r|--running) filter="running";;
      -o|--off)     filter="off" ;;
    esac
    shift
  done

  while read -r line date; do 
    s="$line"
    (( "${#s}" > longest )) && longest="${#s}"
    created="$date"
    [[ -z "$s" ]] && continue
    Sessions["$s"]="1 ${created}"
  done <<< "$(tmux list-sessions -F '#{session_name} #{t:session_created}')"

  for file in "$BLUEPRINTS_D"/*.yaml; do
    [[ -f "$file" ]] || continue
    save_f="${file##*/}"
    save_f="${save_f%\.*}"
    (( "${#save_f}" > "$longest" )) && longest="${#save_f}"
    if [[ -n "${Sessions[$save_f]}" ]]; then
      str="${Sessions[$save_f]}"
      Sessions["$save_f"]="3 ${str#* }"
    else
      created="$(yq_get ".created" "$file")" 
      Sessions["$save_f"]="2 ${created}"
    fi
  done
  out "$longest" "$filter"
}

out() {
  local key val status created score
  local keylen="${1:-17}" filter="${2:-all}"
  for key in "${!Sessions[@]}"; do
    val="${Sessions[$key]}"
    score="${val%% *}"
    status="$(( score-1 ))"
    created="${val#* }"
    case "$filter" in 
      saved) (( score == 1 )) && continue;;
      running) (( score == 2 )) && continue;;
      off) (( score != 2 )) && continue;;
    esac
    printf "%s %-*s%s\n" "${STATE[$status]}" "$((keylen+2))" "${key}" "${created}"   
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  list_sessions "${@}"
fi
