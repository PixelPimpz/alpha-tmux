#!/usr/bin/env bash
[[ -n "$_ALPHA_SETTINGS_SH" ]] && return 0
_ALPHA_SETTINGS_SH=1

if [[ -z "$PLUGIN_ROOT" ]]; then
  if [[ -n "$ZSH_VERSION" ]]; then
    SCRIPT_PATH="$( readlink -f "${(%):-%x}" )"
  else
    SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
  fi
  PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
fi
CONF="${CONF:-$PLUGIN_ROOT/config/settings.yaml}"

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"

# Read any property from the currently active profile
# Usage: get_active "theme" -> "gruvbox-alpha-tmux"
get_active() {
  local prop="$1"
  [[ -f "$CONF" ]] || return 1
  yq_get ".Profiles[] | select(.status == \"active\") | .${prop}" "$CONF"
}

# Write a property to the currently active profile in-place
# Usage: set_active "theme" "nord-alpha-tmux"
set_active() {
  local prop="$1" val="$2"
  [[ -f "$CONF" ]] || return 1
  yq_set "(.Profiles[] | select(.status == \"active\")).${prop}" "$val" "$CONF"
}

# Domain convenience helpers
get_projects()     { get_active "projects"; }
get_active_theme() { get_active "theme"; }
