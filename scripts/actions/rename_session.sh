#!/usr/bin/env bash

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

## core uitls
source "$UTILS/errors.sh"
source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/profiler.sh"

main() {
  local session_cur session_new
  session_cur="$(tmux display -p '#{session_name}')"
  tmux rename-session -t "$session_cur" "$session_new"
  prompt "New name for session ${session_cur}: " session_new
  center "Session $session_cur renamed $session_new."
  pause
}

main "$@"
