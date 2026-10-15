#!/usr/bin/env bash
# ==============================================================================
# load_session.sh — Session Blueprint Loader & Reconstitution Engine
#
# Presents saved session blueprints in a self-sizing dynamic popup.
# - If the selected session is already live in tmux, fast-switches to it.
# - If not live, reconstitutes all windows, layouts, and pane commands from YAML.
# ==============================================================================

[[ -n "$_ALPHA_LOAD_SESSION_SH" ]] && return 0
_ALPHA_LOAD_SESSION_SH=1

SCRIPT_SELF="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
SCRIPT_PATH="$SCRIPT_SELF"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/colorizer.sh"
source "$UTILS/formats.sh"
source "$UTILS/navigator.sh"
source "$UTILS/yqtools.sh"
source "$UTILS/profiler.sh"
source "$UTILS/icons.sh"
# shellcheck source=/dev/null
source "$UTILS/pop.sh"
source "$UTILS/list_sessions.sh"

## Blueprints directory
BLUEPRINTS_D="$(get_option "blueprints" "${XDG_CONFIG_HOME:-$HOME/.config}/alpha-tmux/blueprints")"
BLUEPRINTS_D="${BLUEPRINTS_D/#\~/$HOME}"

BLUEPRINTS=()

load_menu() {
  while IFS= read -r line; do
    [[ -n "$line" ]] && BLUEPRINTS+=( "$line" )
  done < <(list_sessions -s)
}

draw_menu() {
  local ico margin pad cursor selected="${1:-0}"
  local plain max_w=0
  ico="$(get_icon "cursor")"
  ac # clear canvas
  center "${HEADERC}Select session to load${RESET}"
  printf "\n"

  # Measure max visible width across entries for visual centering
  for b in "${BLUEPRINTS[@]}"; do
    plain="$(stripper "$b")"
    (( ${#plain} > max_w )) && max_w=${#plain}
  done

  margin="$(get_margin $(( max_w + 4 )) )"
  printf -v pad "%*s" "$margin" ""

  for i in "${!BLUEPRINTS[@]}"; do
    cursor=" " 
    (( i == selected )) && cursor="$ico"
    printf "%s%s %s\n" "$pad" "$cursor" "${BLUEPRINTS[$i]}"
  done
}

construct() {
  local session bprint root
  local win_c win_n layout
  local pane_c pane_p cmd
  session="$1"
  bprint="$BLUEPRINTS_D/${session}.yaml"  
  [[ ! -f "$bprint" ]] && return 1
  root="$( yq_get ".root" "$bprint" )"
  root="${root:-$HOME}"
  
  win_c="$( yq_len ".windows" "$bprint" )"
  (( win_c == 0 )) && return 1

  for (( w=0; w < win_c; w++ )); do
    win_n="$( yq_get ".windows[$w].name" "$bprint" )"
    layout="$( yq_get ".windows[$w].layout" "$bprint" )"
    pane_c="$( yq_len ".windows[$w].panes" "$bprint" )"
    if (( w == 0 )); then
      tmux new-session -d -s "$session" -c "$root" -n "$win_n"
    else 
      tmux new-window -d -t "$session" -c "$root" -n "$win_n"
    fi
    for (( p=0; p < pane_c; p++ )); do
      pane_p="$( yq_get ".windows[$w].panes[$p].path" "$bprint")"
      cmd="$( yq_get ".windows[$w].panes[$p].command" "$bprint")"
      if (( p > 0 )); then
        tmux split-w -t "${session}:${w}" -c "${pane_p:-$root}"
      fi
      [[ -n "$cmd" ]] && tmux send-keys -t "${session}:${w}.${p}" "$cmd" C-m
    done
    [[ -n "$layout" ]] && tmux select-layout -t "${session}:${w}" "$layout"
  done
  tmux switch-client -t "$session"
  pu_toast -t "Load Session" -d 2.0 "Loaded session: '${session}'."
}

load_session_view() {
  local selected cnt
  load_menu
  if (( ${#BLUEPRINTS[@]} == 0 )); then
    pu_toast -t "Load Session" -d 2.0 "No saved sessions found."
    return 0
  fi

  selected=0
  cnt="${#BLUEPRINTS[@]}"
  cursor off
  trap 'cursor on' EXIT

  while true; do
    draw_menu "$selected"
    local key
    cap_key key
    case "$key" in
      ENTER) 
        break ;;
      ESC|q|Q) 
        cursor on
        exit 0 ;;
      *)
        selected="$(nav_nxt "$selected" "$key" "$cnt")" ;;
    esac
  done
  cursor on

  local session
  read -r icon session created <<< "${BLUEPRINTS[$selected]}"

  # If session already running in tmux, switch directly
  if tmux has-session -t "$session" 2>/dev/null; then
    tmux switch-client -t "$session"
    return 0
  fi

  # Otherwise reconstitute from YAML blueprint
  construct "$session"
}

main() {
  # When invoked inside the popup with 'view', run the interactive canvas
  if [[ "$1" == "view" ]]; then
    load_session_view
    return
  fi

  # Outer launcher: inspect saved sessions and calculate dynamic popup bounds
  load_menu
  if (( ${#BLUEPRINTS[@]} == 0 )); then
    pu_toast -t "Load Session" -d 2.0 "No saved sessions found."
    exit 0
  fi

  local w h
  read -r w h < <( popsizer "Select session to load" "" "${BLUEPRINTS[@]}" )

  popped "" "Load Session" "d" "$w" "$h" "$SCRIPT_SELF" view
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
