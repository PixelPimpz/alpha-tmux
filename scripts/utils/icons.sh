#!/usr/bin/env bash
[[ -n "$_ALPHA_ICONS_SH" ]] && return 0
_ALPHA_ICONS_SH=1

if [[ -z "$PLUGIN_ROOT" ]]; then
  if [[ -n "$ZSH_VERSION" ]]; then
    SCRIPT_PATH="$( readlink -f "${(%):-%x}" )"
  else
    SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
  fi
  PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
fi
ICONS="${ICONS:-$PLUGIN_ROOT/config/icons.yaml}"

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"

# Resolve an icon name from config/icons.yaml into a UTF glyph
# Usage: get_icon "git" -> 󰊢
get_icon() {
  local name="$1" glyph
  [[ -f "$ICONS" ]] || return 1
  glyph="$(yq_get ".icons[] | select(.name == \"$name\") | .glyph" "$ICONS")"
  case "${#glyph}" in
    4) printf "\u$glyph" ;;
    5) printf "\U$glyph" ;;
    *) printf "?" ;;
  esac
}
