#!/usr/bin/env bash

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

## core uitls
source "$UTILS/errors.sh"
source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/profiler.sh"
source "$UTILS/pop.sh"

main() {
  local session_cur session_new
  session_cur="$(tmux display -p '#{session_name}')"
  if session_new="$(pu_input "New name for session:" "$session_cur" "Rename Session")"; then
    # Guard: only rename if non-empty and actually changed
    if [[ -n "$session_new" && "$session_new" != "$session_cur" ]]; then
      # 4: Apply rename and show status toast
      tmux rename-session -t "$session_cur" "$session_new"
      tmux display-message "Session renamed to '$session_new'"
    fi
  fi
}

main "$@"
