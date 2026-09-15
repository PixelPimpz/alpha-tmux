#!/usr/bin/env bash
[[ -n "$_ALPHA_PROFILER_SH" ]] && return 0
_ALPHA_PROFILER_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/utils/pathfinder.sh"
source "$PLUGIN_ROOT/scripts/utils/stepper.sh"

CONF="${CONF:-$(get_config -y)}"
A_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/alpha-tmux"

## Read any property from the currently active profile
# Usage: get_option "theme" -> "gruvbox-alpha-tmux"
get_option(){
  local prop="$1" fallback="$2" profile="$3" val
  [[ -f "$CONF" ]] || return 1

  local m_key="status" m_val="active"
  if [[ -n "$profile" ]]; then
    m_key="name"
    m_val="$profile"
  fi

  val="$(yq_find ".Profiles" "$m_key" "$m_val" "$prop" "$CONF")"
  if [[ -z "$val" || "$val" == "null" ]]; then
    printf "%s\n" "$fallback"
  else
    printf "%s\n" "$val"
  fi
}

## Write a property to the currently active profile in-place
# Usage: set_option "theme" "nord-alpha-tmux"
set_option() {
  local prop="$1" val="$2" profile="$3"
  [[ -f "$CONF" ]] || return 1

  local m_key="status" m_val="active"
  if [[ -n "$profile" ]]; then
    m_key="name"
    m_val="$profile"
  fi

  yq_update ".Profiles" "$m_key" "$m_val" "$prop" "$val" "$CONF"
}

# this function gives me flashbacks to CS101 chapter on pointers and linked lists
# prolly just the use of cur and nxt
step_option() {
  local cur nxt prop="$1" 
  cur="$(get_option "$prop")"
  shift
  nxt="$(stepper "$cur" "$@")"
  set_option "$prop" "$nxt"
}

# get and set session state info on a per-profiloe basis
get_state() {
  local prop="$1" fallback="$2"
  local profile statef val
  profile="$(get_option "name" "Default")"
  statef="$A_CACHE/state_${profile}.yaml"

  [[ -f "$statef" ]] || { printf "%s\n" "$fallback"; return 0; }
  val="$(yq_get ".${prop}" "$statef")"
  [[ "$val" == null ]] && val=""
  printf "%s\n" "${val:-$fallback}"
}

set_state() {
  local prop="$1" val="$2"
  local profile statef
  profile="$(get_option "name" "Default")"
  statef="$A_CACHE/state_${profile}.yaml"

  mkdir -p "$A_CACHE"
  [[ -f "$statef" ]] || touch "$statef"
  yq_set ".${prop}" "$val" "$statef"
}

# Domain convenience helpers
get_projects()     { get_option "projects"; }
get_active_theme() { get_option "theme"; }

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  "$@"
fi
