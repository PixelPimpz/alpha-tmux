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
MODE="window"

load_projects() {
  local p_name dir
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

  if [[ "$MODE" == "window" ]]; then
    tmux rename-window -t "$TMUX_PANE" "$p_name"
    tmux respawn-pane -k -c "$dir" -t "$TMUX_PANE" "${PLUGIN_ROOT}/run"
  else
    # Session Mode: Create detached if it doesn't exist, set PATH, and switch
    if ! tmux has-session -t "=$p_name" 2>/dev/null; then
      tmux new-session -d -s "$p_name" -c "${PLUGIN_ROOT}/run"
    fi
    [[ -d "$dir/bin" ]] && tmux setenv -t "=$p_name" PATH "$dir/bin:$PATH"
    tmux switch-client -t "=$p_name"
  fi

  exit 0
}

toggle() {
  local mode
  mode="$( get_option "mode" )"
  case "$mode" in
    window) mode="session" ;;
    session) mode="window" ;;
  esac
  MODE="$mode"
  set_option "mode" "$mode"
}

draw_menu() {
  local selected="${1:-0}"

  # in case no git-tracked sub dirs found in $PROJECTS
  if (( "${#PROJECTS[@]}" == 0 )); then
    boxer "$BORDERC" "No project directories in $PROJECTS_D." "${ACCENTC}$(get_icon "warning")${RESET}"
    pause
    exit 0
  fi

  ac
  printf "\n"

  # load icons needed into cache. Keepin' it fast!
  local selector git folder check
  selector="$(get_icon "cursor")"
  git="$(get_icon "git")"
  folder="$(get_icon "folder")"
  check="$(get_icon "pass")"

  # build & center mode badges
  local badge_win badge_sess
  if [[ "$MODE" == "window" ]]; then
    badge_win="${BRACKETC}[ ${ACCENTC}${check} ${TEXTC}Window ${BRACKETC}]${RESET}"
    badge_sess="${MUTEDC}[   Session ]${RESET}"
  else
    badge_win="${MUTEDC}[   Window ]${RESET}"
    badge_sess="${BRACKETC}[ ${ACCENTC}${check} ${TEXTC}Session ${BRACKETC}]${RESET}"
  fi

  center "$badge_win    $badge_sess"
  printf "\n"

  # calculate margin and pad lines
  local margin pad
  margin="$(get_margin 24)"
  printf -v pad "%*s" "$margin" ""

  local num=0 icon dirty cursor
  for p_name in "${PROJECTS[@]}"; do
    (( num++ ))
    (( num - 1 != selected )) && cursor="  " || cursor="$selector "
    is_git   "$p_name" &>/dev/null && icon="$git" || icon="$folder"
    is_dirty "$p_name" &>/dev/null && dirty="*"   || dirty=""
    printf "%s%s%s %s %s %s\n" "$pad" "$cursor" "[$num]" "$icon" "${p_name##*/}" "$dirty"
  done

  printf "\n"
  center "${MUTEDC}$(keys "TAB") to toggle mode: ${TEXTC}Window ${ACCENTC}$(get_icon "toggle")${TEXTC} Session${RESET}"
}

main() {
  trap 'cursor on' EXIT INT TERM
  cursor off

  load_projects
  local selected=0
  local count="${#PROJECTS[@]}"
  local key

  while true; do
    draw_menu "$selected"
    cap_key key || break

    case "$key" in
      UP|k|K|DOWN|j|J|[1-9])
        selected="$(nav_nxt "$selected" "$key" "$count")"
        ;;
      $'\t'|TAB)
        toggle
        ;;
      ENTER)
        jump "${PROJECTS[$selected]}"
        break
        ;;
      ESC|q|Q)
        break
        ;;
    esac
  done

  cursor on
  ac
}

main
