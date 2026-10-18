#!/usr/bin/env bash
# ==============================================================================
# save_session.sh — Session Blueprint Serializer
#
# Supports two modes of operation:
#   1. Quick Save (default):
#      - If session has a custom name: saves/overwrites immediately without prompts.
#      - If session has an auto-assigned numeric name (e.g. 0, 1): prompts for a
#        meaningful name and renames the active session.
#   2. Save As (--as / -a):
#      - Always prompts for a session name (pre-seeded with current name).
#      - Confirms overwrite if the target blueprint YAML file already exists.
#      - Renames the live tmux session to match the new blueprint name.
# ==============================================================================

SCRIPT_SELF="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
SCRIPT_PATH="$SCRIPT_SELF"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

## Core utilities
source "$UTILS/errors.sh"
source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/profiler.sh"
source "$UTILS/pop.sh"

## Target directory where session blueprint YAMLs are persisted
BLUEPRINTS_D="$(get_option "blueprints" "${XDG_CONFIG_HOME:-$HOME/.config}/alpha-tmux/blueprints")"
BLUEPRINTS_D="${BLUEPRINTS_D/#\~/$HOME}"

# ------------------------------------------------------------------------------
# serialize_session <target_session> <output_yaml_file> <session_display_name>
#
# Inspects the live tmux session hierarchy (windows, layouts, panes, working
# directories, active commands) and writes a structured blueprint to disk.
# ------------------------------------------------------------------------------
serialize_session() {
  local target_session="$1"
  local target_file="$2"
  local target_name="$3"
  local root_d created

  # Extract session-level working directory and creation timestamp
  root_d="$( tmux display -p -t "$target_session" '#{pane_current_path}' )"
  created="$( tmux display -p -t "$target_session" '#{t:session_created}' )"

  cat <<EOF > "$target_file"
name: "$target_name"
created: "$created"
root: "$root_d"
windows:
EOF

  # 1. Iterate through every window in the session
  while IFS="|" read -r win_idx win_name win_layout; do
    cat <<EOF >> "$target_file"
  - name: "$win_name"
    layout: '$win_layout'
    panes:
EOF

    # 2. Iterate through each pane inside this window
    while IFS="|" read -r _ pane_path pane_cmd; do
      # If the pane is merely running an interactive shell, record as blank
      # so reconstruction launches the user's default login shell
      [[ "$pane_cmd" =~ ^(bash|zsh|fish|sh)$ ]] && pane_cmd=""
      cat <<EOF >> "$target_file"
      - path: "$pane_path"
        command: "$pane_cmd"
EOF
    done < <(tmux list-panes -t "${target_session}:${win_idx}" -F '#{pane_index}|#{pane_current_path}|#{pane_current_command}')
  done < <(tmux list-windows -t "$target_session" -F '#{window_index}|#{window_name}|#{window_layout}')
}

# ------------------------------------------------------------------------------
# main [--as|-a]
#
# Entry point: determines save mode, handles user prompts/collision checks,
# invokes the serializer, and displays feedback.
# ------------------------------------------------------------------------------
main() {
  local mode="save"
  if [[ "$1" == "--as" || "$1" == "-a" || "$1" == "as" ]]; then
    mode="save_as"
  fi

  local session_name
  session_name="$(tmux display -p '#{session_name}')"
  mkdir -p "$BLUEPRINTS_D"

  local bp_name="$session_name"
  local bp_file

  # Determine if user input is required:
  # - Save As always prompts.
  # - Quick Save prompts ONLY if the session has an auto-numeric name (e.g. 0, 1).
  if [[ "$mode" == "save_as" || "$session_name" =~ ^[0-9]+$ ]]; then
    local init_val="$session_name"
    [[ "$session_name" =~ ^[0-9]+$ ]] && init_val=""

    local prompt_title="Save Session"
    [[ "$mode" == "save_as" ]] && prompt_title="Save Session As"

    bp_name="$(pu_input "Session name:" "$init_val" "$prompt_title")" || return 1
    [[ -z "$bp_name" ]] && return 1

    bp_file="$BLUEPRINTS_D/${bp_name}.yaml"

    # Collision guard: warn and confirm before overwriting an existing blueprint
    if [[ -f "$bp_file" ]]; then
      pu_confirm "Session '$bp_name' exists. Overwrite?" "Overwrite Session" 1 "Overwrite" "Cancel" || return 1
    fi

    # Synchronize live tmux session name if saving under a new name
    if [[ "$session_name" != "$bp_name" ]]; then
      if ! tmux has-session -t "=$bp_name" 2>/dev/null; then
        tmux rename-session -t "$session_name" "$bp_name" 2>/dev/null
        session_name="$bp_name"
      fi
    fi
  else
    # Quick Save on an already-named session: instant overwrite
    bp_file="$BLUEPRINTS_D/${bp_name}.yaml"
  fi

  # Write the session blueprint YAML
  serialize_session "$session_name" "$bp_file" "$bp_name"

  # Display success feedback toast
  pu_toast -t "Save Session" -d 2.0 -s "${bp_file/#$HOME/\~}" "Session '${bp_name}' saved"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
