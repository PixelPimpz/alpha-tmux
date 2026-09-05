#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/formats.sh" # ac (all_clear)
source "$PLUGIN_ROOT/scripts/utils/settings.sh" # get_config --tmux 

printf "\n\n"
center "Reloading tmux.conf. Please wait."
tmux source-file "$(get_config -t)"
center "Done."
pause -b 'Press any key to return to main menu.'
