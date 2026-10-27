#!/usr/bin/env bash
[[ -n "$_ALPHA_PLUGMAN_SH" ]] && return 0
_ALPHA_PLUGMAN_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
PLUGINS_D="$PLUGIN_ROOT/plugins"
A_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/alpha-tmux"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/yqtools.sh"
source "$UTILS/stepper.sh"

get_opt() {
  local plug="$1" prop="$2" fallback="$3" val
  local pfile="$PLUGINS_D/$plug/plugin.yaml"
  [[ -f "$pfile" ]] || { printf "%s\n" "$fallback"; return 1; }

  val="$(yq_get ".${prop}" "$pfile")"
  [[ "$val" == "null" ]] && val=""
  printf "%s\n" "${val:-$fallback}"
}

set_opt() {
  local plug="$1" prop="$2" val="$3"
  local pfile="$PLUGINS_D/$plug/plugin.yaml"
  [[ -f "$pfile" ]] || return 1

  yq_set ".${prop}" "$val" "$pfile"
}

step_opt() {
  local plug="$1" prop="$2" cur nxt
  cur="$(get_opt "$plug" "$prop")"
  shift 2
  nxt="$(stepper "$cur" "$@")"
  set_opt "$plug" "$prop" "$nxt"
}
