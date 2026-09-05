#!/usr/bin/env bash
[[ -n "$_ALPHA_SETTINGS_SH" ]] && return 0
_ALPHA_SETTINGS_SH=1

if [[ -z "$PLUGIN_ROOT" ]]; then
  SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
  PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
fi
CONF="${CONF:-$PLUGIN_ROOT/config/settings.yaml}"

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"

## Read any property from the currently active profile
# Usage: get_active "theme" -> "gruvbox-alpha-tmux"
get_active() {
  local prop="$1"
  [[ -f "$CONF" ]] || return 1
  yq_get ".Profiles[] | select(.status == \"active\") | .${prop}" "$CONF"
}

## Write a property to the currently active profile in-place
# Usage: set_active "theme" "nord-alpha-tmux"
set_active() {
  local prop="$1" val="$2"
  [[ -f "$CONF" ]] || return 1
  yq_set "(.Profiles[] | select(.status == \"active\")).${prop}" "$val" "$CONF"
}

## Helper to grab either the local settings.yaml for this plugin or
# the main tmux config file.
# USAGE: get_config [-t|--tmux] [-y|--yaml] (default)
get_config() {
  local file
  case "$1" in
    -t|--tmux)
      while read -r line; do
        if [[ -f "$line" ]]; then
          file="$line"
          break 
        else
          continue
        fi
      ## the default paths tmux automatically looks through
      # use caution when editing these
      done <<- EOF
        ${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf
        $HOME/.tmux.conf
        $HOME/.config/tmux.conf
        /etc/tmux.conf
EOF
# ^ keep this here to avoid EOF errors in all editors
    ;;
    -y|--yaml|*)
      file="$PLUGIN_ROOT/config/settings.yaml" ;;
  esac
  printf "%s\n" "$file"
}
  
# Domain convenience helpers
get_projects()     { get_active "projects"; }
get_active_theme() { get_active "theme"; }
