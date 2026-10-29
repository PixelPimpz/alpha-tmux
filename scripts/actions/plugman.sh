#!/usr/bin/env bash
[[ -n "$_ALPHA_PLUGMAN_SH" ]] && return 0
_ALPHA_PLUGMAN_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"
UI="$PLUGIN_ROOT/scripts/ui"

source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/icons.sh"
source "$UTILS/boxer.sh"
source "$UTILS/navigator.sh"
source "$UTILS/pop.sh"
source "$UTILS/plugtools.sh"
source "$UI/headers.sh"
source "$UI/menus.sh"

left_menu(){
  local yaml="$PLUGIN_ROOT/config/menus/plugman.yaml"
  local cnt b k v
  LEFT_ITEMS=()
  cnt="$(yq_len ".columns[0].buttons" "$yaml")"
  for (( b = 0; b < cnt; b++ )); do
    local -A BTN=()
    while IFS="=" read -r k v; do
      [[ -n "$k" ]] && BTN["$k"]="$v"
    done < <(yq_button_props 0 "$b" "$yaml")
    [[ -n "${BTN[name]}" ]] && LEFT_ITEMS+=("${BTN[name]}|${BTN[icon]}|${BTN[comm]}")
  done
}

right_menu() {
  local pdir plug ui title ico state prop o_label o_ico values
  RIGHT_ITEMS=()
  for pdir in "$PLUGINS_D"/*; do
    [[ -f "$pdir/plugin.yaml" ]] || continue
    plug="$(basename "$pdir")"
    title="$(get_opt "$plug" "title" "$plug")"
    ico="$(get_opt "$plug" "icon" "plug")"
    state="$(get_opt "$plug" "enabled" "ON")"
    ui="$(get_opt "$plug" "ui" "")"

    local opts=()
    mapfile -t opts < <(yq_plug_opts "$pdir/plugin.yaml")

    if [[ -n "$ui" ]] || (( ${#opts[@]} > 1 )); then
      RIGHT_ITEMS+=("${title}: ${state}|${ico}|detail:plug_ui:${plug}|${plug}")
    elif (( ${#opts[@]} == 1 )); then
      IFS="|" read -r prop o_label o_ico values <<< "${opts[0]}"
      RIGHT_ITEMS+=("${o_label}$(get_opt "$plug" "$prop")|${o_ico:-$ico}|step_opt $plug $prop $values|${plug}")
    else
      RIGHT_ITEMS+=("${title}: ${state}|${ico}|step_opt $plug enabled ON OFF|${plug}")
    fi
  done
}
