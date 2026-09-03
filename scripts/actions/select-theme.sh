#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
#CONF="$PLUGIN_ROOT/config/settings.yaml"

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh" # for get_icon()
source "$PLUGIN_ROOT/scripts/utils/formats.sh" # for boxed()
source "$PLUGIN_ROOT/scripts/utils/errors.sh" # for fatal() and error()
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh" # styling

MENU=()

draw_menu() {
  local menu item count
}

main(){
  local ico_dk ico_lt ico_sel
  local sampl
}
