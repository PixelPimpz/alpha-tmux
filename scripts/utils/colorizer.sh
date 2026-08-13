#!/usr/bin/env bash
#PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
THEME="$PLUGIN_ROOT/themes/${1:-gruvbox-alpha-tmux}.yaml"
HEX2ANSI="$PLUGIN_ROOT/scripts/utils/hex2ansi.sh"
COLOR_HEADER="$( "$HEX2ANSI" "$(yq e '.ui.header' "$THEME" )")"
COLOR_TAGLINE="$( "$HEX2ANSI" "$(yq e '.ui.tagline' "$THEME" )")"
RESET=$'\033[0m'
