#!/usr/bin/env bash
[[ -n "$_ALPHA_PROFILER_SH" ]] && return 0
_ALPHA_PROFILER_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/utils/pathfinder.sh"

CONF="${CONF:-$(get_config -y)}"

## Read any property from the currently active profile
# Usage: get_active "theme" -> "gruvbox-alpha-tmux"
get_active() {
  local prop="$1"
  [[ -f "$CONF" ]] || return 1
  yq_find ".Profiles" "status" "active" "$prop" "$CONF"
}

## Write a property to the currently active profile in-place
# Usage: set_active "theme" "nord-alpha-tmux"
set_active() {
  local prop="$1" val="$2"
  [[ -f "$CONF" ]] || return 1
  yq_update ".Profiles" "status" "active" "$prop" "$val" "$CONF"
}

# Domain convenience helpers
get_projects()     { get_active "projects"; }
get_active_theme() { get_active "theme"; }
