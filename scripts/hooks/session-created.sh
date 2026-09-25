#!/usr/bin/env bash
# shellcheck disable=SC1091
[[ -n "$_ALPHA_SESSION_CREATED_SH" ]] && return 0
_ALPHA_SESSION_CREATED_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"
ACTIONS="$PLUGIN_ROOT/scripts/actions"

source "$UTILS/profiler.sh"
source "$UTILS/pop.sh"
source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"

PROJECTS_D="$(get_projects)"
TARGET="${1:-:0.0}"

main() {
  local startup proj 
  startup="$(get_option "startup" "last")"

  case "$startup" in
    none)
      return 0 ;;

    last)
      proj="$(get_state "last_project")"
      [[ -z "$proj" ]] && proj="$(get_option "defaultd")"
      ;;

    default)
      proj="$(get_option "defaultd")" 
      ;;
    menu|*)
      proj="" 
      ;; 
  esac
  local target_dir="${PROJECTS_D%/}/$proj"

  if [[ -n "$proj" && -d "$target_dir" ]]; then
    tmux rename-window -t "$TARGET" "$proj"
    tmux respawn-pane -k -c "$target_dir" -t "$TARGET" "$PLUGIN_ROOT/run"
  else
    tmux respawn-pane -k -t "$TARGET" "$PLUGIN_ROOT/run"
    popped "$ACTIONS/to_project.sh" "Jump To Project..." "m"
  fi
}
main "$@"
