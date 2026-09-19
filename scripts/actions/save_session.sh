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
    session_name="${bp_name:-$session-name}"
  fi
  local bp_file="$BLUEPRINTS_D/${session_name}.yaml"
  local root_d
  root_d="$( tmux display -p -t "$session_name" '#{pane_current_path}' )"
  cat <<EOF > "$bp_file"
name: "$session_name"
root: "$root_d"
windows:
EOF
  while IFS="|" read -r win_idx win_name win_layout; do
    cat <<EOF >> "$bp_file"
  - name: "$win_name"
    layout: "$win_layout"
    panes:
EOF
    # 3. Iterate through each pane inside this window
    while IFS="|" read -r _ pane_path pane_cmd; do
      # If the pane is just running an interactive shell, leave command blank
      [[ "$pane_cmd" =~ ^(bash|zsh|fish|sh)$ ]] && pane_cmd=""
      cat <<EOF >> "$bp_file"
      - path: "$pane_path"
        command: "$pane_cmd"
EOF
    done < <(tmux list-panes -t "${session_name}:${win_idx}" -F '#{pane_index}|#{pane_current_path}|#{pane_current_command}')
  done < <(tmux list-windows -t "$session_name" -F '#{window_index}|#{window_name}|#{window_layout}')

  tmux display-message "Session '${session_name}' saved as blueprint."
}

main "$@"
