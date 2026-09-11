#!/usr/bin/env bash
[[ -n "$_ALPHA_PROFILER_SH" ]] && return 0
_ALPHA_PROFILER_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/utils/pathfinder.sh"
source "$PLUGIN_ROOT/scripts/utils/stepper.sh"

CONF="${CONF:-$(get_config -y)}"

## Read any property from the currently active profile
# Usage: get_option "theme" -> "gruvbox-alpha-tmux"
get_option() {
  local prop="$1"
  [[ -f "$CONF" ]] || return 1
  yq_find ".Profiles" "status" "active" "$prop" "$CONF"
}

## Write a property to the currently active profile in-place
# Usage: set_option "theme" "nord-alpha-tmux"
set_option() {
  local prop="$1" val="$2"
  [[ -f "$CONF" ]] || return 1
  yq_update ".Profiles" "status" "active" "$prop" "$val" "$CONF"
}

step_option() {
  local cur nxt prop="$1" 
  cur="$(get_option "$prop")"
  shift
  nxt="$(stepper "$cur" "$@")"
  set_option "$prop" "$nxt"
}

# Domain convenience helpers
get_projects()     { get_option "projects"; }
get_active_theme() { get_option "theme"; }
