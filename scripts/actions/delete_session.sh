#!/usr/bin/env bash
[[ -n "$_ALPHA_DELETE_SESSION_SH" ]] && return 0
_ALPHA_DELETE_SESSION_SH=1

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
source "$UTILS/pop.sh"
source "$UTILS/list_sessions.sh"

## Blueprints store in: 
BLUEPRINTS_D="$(get_option "blueprints" "${XDG_CONFIG_HOME:-$HOME/.config}/alpha-tmux/blueprints")"
BLUEPRINTS_D="${BLUEPRINTS_D/#\~/$HOME}"

BLUEPRINTS=()

load_menu() {
  BLUEPRINTS=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && BLUEPRINTS+=( "$line" )
  done < <(list_sessions -s)
}

draw_menu() {
 local ico margin pad cursor selected="${1:-0}"
 local plain max_w=0
 ico="$(get_icon "cursor")"
 ac # cleras canvas
 center "${HEADERC}Select session to delete${RESET}"
 printf "\n"
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


delete_session_view() {
  local selected cnt icon session created
  load_menu
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
        read -r icon session created <<< "${BLUEPRINTS[$selected]}"
        pu_confirm_view "Delete $session?" 0 "Delete" "Cancel" || continue
        rm "$BLUEPRINTS_D/$session.yaml"
        pu_toast_view "$session deleted." 1.5
        BLUEPRINTS=()
        load_menu
        cnt="${#BLUEPRINTS[@]}"
        if (( cnt == 0 )); then
          pu_toast_view "No sessions left." 1.5
          break
        fi
        (( selected >= cnt )) && selected=$(( cnt - 1 )) ;;
      ESC|q|Q)
        cursor on
        exit 0 ;;
      *)
        selected="$(nav_nxt "$selected" "$key" "$cnt")" ;;
    esac
  done
}

main() {
  if [[ "$1" == "view" ]]; then
    delete_session_view
    return
  fi

  load_menu
  if (( ${#BLUEPRINTS[@]} == 0 )); then
    pu_toast -t "Delete Session" -d 2.0 "No sessions found."
    exit 0
  fi

  local w h
  read -r w h < <( popsizer "Select session to delete" "" "${BLUEPRINTS[@]}" )

  popped "" "Delete Session" "d" "$w" "$h" "$SCRIPT_SELF" view
}

main "$@"
