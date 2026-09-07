#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/profiler.sh"
source "$UTILS/gitools.sh"
source "$UTILS/icons.sh"
source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/navigator.sh"
source "$UTILS/boxer.sh"

PROJECTS=()
PROJECTS_D=""

load_projects() {
  local projects_d p_name dir
  PROJECTS_D="$(get_projects)"
  for dir in "${PROJECTS_D%/}"/*; do
    [[ ! -d "$dir" ]] && continue
    p_name="${dir##*/}"
    [[ "$p_name" =~ ^\. ]] && continue
    PROJECTS+=("$dir")
  done
}

jump() {
  local dir p_name
  dir="$1"
  p_name="${dir##*/}"
}

toggle() {
  local mode
  mode="$( get_active "mode" )"
  case "$mode" in
    window) mode="session" ;;
    session) mode="window" ;;
  esac
  set_active "mode" "$mode"
}

draw_menu() {
  local icon dirty git folder p_name cursor num=0
  cursor="$(get_icon "cursor")"
  git="$(get_icon "git")"
  folder="$(get_icon "folder")"
  if (( "${#PROJECTS[@]}" == 0 )); then
    boxer "$BORDERC" "No project directories in $PROJECTS_D." "${ACCENTC}$(get_icon "warning")${RESET}"
    pause
    exit 0
  fi
  for p_name in "${PROJECTS[@]}"; do
    (( num++ ))
    is_git   "$p_name" &>/dev/null && icon="$git" || icon="$folder"
    is_dirty "$p_name" &>/dev/null && dirty="*"   || dirty=""
    printf "%s %s %s %s\n" "$cursor" "$icon" "${p_name##*/}" "$dirty"
  done
}
