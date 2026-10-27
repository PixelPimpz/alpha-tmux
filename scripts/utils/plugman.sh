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

unit() {
  local target="$1" depth="${2:-1}"
  local pdir plug enabled punit only_main start draw
  for pdir in "$PLUGINS_D"/*; do 
    [[ -f "$pdir/plugin.yaml" ]] || continue
    plug="$( basename "$pdir" )"
    
    enabled="$( get_opt "$plug" "enabled" "ON" )"
    [[ "$enabled" =~ ^(ON|1|true)$ ]] || continue
    
    punit="$( get_opt "$plug" "unit" "none" )"
    [[ "$punit" == "$target" ]] || continue

    only_main="$( get_opt "$plug" "only_main" "1" )" 
    if [[ "$only_main" =~ ^(ON|1|true)$ ]] && (( depth >1 )); then
      continue
    fi

    start="$( get_opt "$plug" "entry" "init.sh" )" ## i would like start instead of entry
    draw="$( get_opt "$plug" "render" "${plug}_render" )" ## also "draw" > "render"

    if [[ -f "$pdir/$start" ]]; then
      source "$pdir/$start";
      declare -F "$draw" >/dev/null && "$draw"
    fi
  done
}
