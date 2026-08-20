#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
ca
tmux display-popup -E | tmux source-file "$HOME/.config/tmux/tmux.conf"; echo 'tmux.conf reloaded...'
sleep 3
