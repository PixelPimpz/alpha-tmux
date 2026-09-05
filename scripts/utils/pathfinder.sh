#!/usr/bin/env bash
## pathfinder.sh is your handy guide to the 
# many exciting destinations around the apha
# plugin! Use these handy functions to quickly 
# retrieve important paths
[[ -n "$_ALPHA_PATHFINDER_SH" ]] && return 0
_ALPHA_PATHFINDER_SH=1

PLUGIN_ROOT="${PLUGIN_ROOT:-$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )/../.." && pwd )}"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/errors.sh"

get_plug_root() {
  local pr
  pr="$( tmux showenv -g PLUGIN_ROOT 2>/dev/null )"
  pr="${pr#*=}"
  printf "%s\n" "${pr:-$PLUGIN_ROOT}"
}

set_plug_root() {
  local proot="${1:-$PLUGIN_ROOT}"
  if [[ ! -d "$proot" ]]; then
    error "$proot: no such file or directory"
    return 1
  fi
  PLUGIN_ROOT="${proot:-$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )/../.." && pwd )}"
  tmux setenv -g PLUGIN_ROOT "$PLUGIN_ROOT"
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
