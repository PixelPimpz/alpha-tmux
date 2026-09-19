#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

## core uitls
source "$UTILS/errors.sh"
source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/profiler.sh"

## Blueprints store in: 
BLUEPRINTS_D="$(get_option "blueprints" "${XDG_CONFIG_HOME:-$HOME/.config}/alpha-tmux/blueprints")"
BLUEPRINTS_D="${BLUEPRINTS_D/#\~/$HOME}"

main() {
  local session_name
  mkdir -p "$BLUEPRINTS_D"
  session_name="$(tmux display -p '#{session_name}')"
  if [[ "$session_name" =~ ^[0-9]+$ ]]; then
    prompt "Blueprint name: " bp_name
    [[ -z "$bp_name" ]] && exit
    tmux rename-session -t "$session_name" "$bp_name"
    session_name="$bp_name"
  fi
}

main "$@"
