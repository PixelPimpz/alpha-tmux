#!/usr/bin/env bash
[[ -n "$_ALPHA_MENU_GEN_SH" ]] && return 0
_ALPHA_MENU_GEN_SH=1

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/utils/render_grid.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

## -----------------------------------------------------------------
# MENU_GEN responsible for generating the main/base alpha-tmux menu
## -----------------------------------------------------------------
menu_gen() {
  local len max; max=0
  local menu="${1:-$PLUGIN_ROOT/lib/menu-main.yaml}"
  local Buttons=()

  # 1. Calculate max label width across buttons
  while read -r name; do
    len="${#name}"
    (( len > max )) && max="$len"
  done < <(yq e '.Buttons[].name' "$menu")

  while read -r key; do
    Buttons+=("$(make_button "$key" "$max")")
  done < <(yq e '.Buttons[].key' "$menu")

  # 3. Render grid & print selection prompt
  render_grid "${Buttons[@]}"
  center -n "Enter menu selection or press [ENTER 󰌑 ] for a ${SHELL##*/} prompt: " "$PROMPTC"
}
