#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/formats.sh" # ac (all_clear)
source "$UTILS/pathfinder.sh" # get_config --tmux 
source "$UTILS/pop.sh" # popups 

tmux source-file "$(get_config -t)"
pu_toast 'Tmux config reloaded.' 'Reload' 1.5
