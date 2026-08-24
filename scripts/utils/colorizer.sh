#!/usr/bin/env bash
[[ -n "$_ALPHA_COLORIZER_SH" ]] && return 0
_ALPHA_COLORIZER_SH=1

_active_theme="$(get_active_theme 2>/dev/null)"
THEME="$PLUGIN_ROOT/themes/${_active_theme:-gruvbox-alpha-tmux}.yaml"
HEX2ANSI="$PLUGIN_ROOT/scripts/utils/hex2ansi.sh"
get_color() {
  "$HEX2ANSI" "$(yq e "$1" "$THEME")"
}
get_bg_color() {
  "$HEX2ANSI" -bg "$(yq e "$1" "$THEME")"
}

HEADERC="$(get_color '.ui.header')"
TAGLINEC="$(get_color '.ui.tagline')"
BORDERC="$(get_color '.ui.border')"
BRACKETC="$(get_color '.ui.bracket')"
KEYC="$(get_color '.ui.menu_key')"
TEXTC="$(get_color '.ui.menu_text')"
ICONC="$(get_color '.ui.menu_icon')"
BUTTON_BGC="$(get_bg_color '.ui.button_bg // .palette.bg1')"
ACCENTC="$(get_color '.ui.accent')"
PROMPTC="$(get_color '.ui.prompt // .ui.accent')"
RESET=$'\033[0m'
