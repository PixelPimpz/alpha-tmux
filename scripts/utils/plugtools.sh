#!/usr/bin/env bash
[[ -n "$_ALPHA_PLUGTOOLS_SH" ]] && return 0
_ALPHA_PLUGTOOLS_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
PLUGINS_D="$PLUGIN_ROOT/plugins"
A_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/alpha-tmux"
UTILS="$PLUGIN_ROOT/scripts/utils"
CONFIG="$PLUGIN_ROOT/config"

CATALOG="$CONFIG/catalog.yaml"

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
  local plugd plug enabled punit only_main start draw
  for plugd in "$PLUGINS_D"/*; do 
    [[ -f "$plugd/plugin.yaml" ]] || continue
    plug="$( basename "$plugd" )"
    
    enabled="$( get_opt "$plug" "enabled" "ON" )"
    [[ "$enabled" =~ ^(ON|1|true)$ ]] || continue
    
    punit="$( get_opt "$plug" "unit" "none" )"
    [[ "$punit" == "$target" ]] || continue

    only_main="$( get_opt "$plug" "only_main" "1" )" 
    if [[ "$only_main" =~ ^(ON|1|true)$ ]] && (( depth >1 )); then
      continue
    fi

    start="$( get_opt "$plug" "start" "init.sh" )" ## i would like start instead of start
    draw="$( get_opt "$plug" "draw" "${plug}_draw" )" ## also "draw" > "draw"

    if [[ -f "$plugd/$start" ]]; then
      source "$plugd/$start";
      declare -F "$draw" >/dev/null && "$draw"
    fi
  done
}

# synchronize 
sync() {
  :
}

remove() {
  local plug
  for plug in "$@"; do
    [[ -n "$plug" ]] || continue
    rm -rf "${PLUGINS_D:?}/$plug"
    yq_delete ".installed" "name" "$plug" "$CATALOG"
  done
}

update() {
  local plug plugd
  for plug in "$@"; do 
    plugd="${PLUGINS_D}/$plug"
    [[ -d "$plugd/.git" ]] || continue
    if type -P "pv" &>/dev/null; then
      git -C "$plugd" pull --ff-only --progress 2>&1 | pv -t -N "$plug" >/dev/null
      :
    else
      git -C "$plugd" pull --ff-only
    fi
  done
}

install() {
  local repo plug plugd url title ico desc
  for repo in "$@"; do
    plug="${repo##*/}"
    plugd="${PLUGINS_D}/$plug"
    url="https://github.com/${repo}.git"
    if type -P "pv" &>/dev/null; then
      git clone --progress "$url" "$plugd" 2>&1 | pv -t -N "$plug" >/dev/null
    else 
      git clone -q "$url" "$plugd"
    fi
    [[ -f "$plugd/plugin.yaml" ]] || continue
    title="$(get_opt "$plug" "title" "$plug")"
    ico="$(get_opt "$plug" "icon" "plug")"
    desc="$(get_opt "$plug" "desc" "")"
    yq_delete ".installed" "name" "$plug" "$CATALOG"
    yq_add ".installed" "$CATALOG" "name=$plug" "title=$title" "icon=$ico" "repo=$repo" "desc=$desc" 
  done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  "$@"
fi
