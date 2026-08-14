#!/usr/bin/env bash
#PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
THEME="$PLUGIN_ROOT/themes/${1:-gruvbox-alpha-tmux}.yaml"
HEX2ANSI="$PLUGIN_ROOT/scripts/utils/hex2ansi.sh"
get_color() {
  "$HEX2ANSI" "$(yq e "$1" "$THEME")"
}

HEADERC="$(get_color '.ui.header')"
TAGLINEC="$(get_color '.ui.tagline')"
BORDERC="$(get_color '.ui.border')"
BRACKETC="$(get_color '.ui.bracket')"
KEYC="$(get_color '.ui.menu_key')"
TEXTC="$(get_color '.ui.menu_text')"
ICONC="$(get_color '.ui.menu_icon')"
RESET=$'\033[0m'
