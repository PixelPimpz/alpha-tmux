#!/usr/bin/env bash
[[ -n "$_ALPHA_LOAD_SESSION_SH" ]] && return 0
_ALPHA_LOAD_SESSION_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/colorizer.sh"
source "$UTILS/formats.sh"
source "$UTILS/navigator.sh"
source "$UTILS/yqtools.sh"
source "$UTILS/profiler.sh"
source "$UTILS/icons.sh"
source "$UTILS/pop.sh"
source "$UTILS/list_sessions.sh"

## Blueprints store in: 
BLUEPRINTS_D="$(get_option "blueprints" "${XDG_CONFIG_HOME:-$HOME/.config}/alpha-tmux/blueprints")"
BLUEPRINTS_D="${BLUEPRINTS_D/#\~/$HOME}"

BLUEPRINTS=() ## the array ofactual blueprints

load_menu() {
  while IFS= read -r line; do
    [[ -n "$line" ]] && BLUEPRINTS+=( "$line" )
  done < <(list_sessions -s)
}

draw_menu() {
  local ico margin pad cursor selected="${1:-0}"
  ico="$(get_icon "cursor")"
  ac # cleras canvas
  center "${HEADERC}Select session to load${RESET}"
  printf "\n"
  
  margin="$(get_margin 44)"
  printf -v pad "%*s" "$margin" ""

  for i in "${!BLUEPRINTS[@]}"; do
    cursor=" " 
    (( i == selected )) && cursor="$ico"
    printf "%s%s %s\n" "$pad" "$cursor" "${BLUEPRINTS[$i]}"
  done
}

construct () {
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
    if (( w == 0 ));then
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
  pu_toast -t "Load Blueprint" -d 3.0 "Loaded session: '${session}'."
}

main() {
  local selected cnt
  load_menu
  if (( "${#BLUEPRINTS[@]}" == 0 )); then
    pu_toast -t "No Blueprints found." -d "3.0"
    exit
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
        exit ;;
      *)
        selected="$(nav_nxt "$selected" "$key" "$cnt")" ;;
    esac
  done
  local session
  read -r icon session created <<< "${BLUEPRINTS[$selected]}"

  if tmux has-session -t "$session" 2>/dev/null; then
    tmux switch-client -t "$session"
    return 0
  fi

  construct "$session"
}

main "$@"
