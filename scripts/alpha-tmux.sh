#!/usr/bin/env bash
#version 2 of our main shell script 
## not to be used until everything being re-factored 
## is living comfortably in their new NPC Housing.
##----------------------------------------------------
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/.." && pwd )"
tmux set-env -g DOTFILES "$HOME/dotfiles"
tmux set-env -g ACTIONS "$PLUGIN_ROOT/scripts/actions"

##--------[ load built-in utils ]---------------------
source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"
source "$PLUGIN_ROOT/scripts/utils/render_grid.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/builtin/header_gen.sh"
source "$PLUGIN_ROOT/scripts/builtin/menu_gen.sh"
##--------[ additional modules go here ]--------------

##----------------------------------------------------

main() {
  local menu="${1:-$PLUGIN_ROOT/lib/menu-main.yaml}"
  header_gen
  center " "
  menu_gen "$menu"
}

main "$@"
