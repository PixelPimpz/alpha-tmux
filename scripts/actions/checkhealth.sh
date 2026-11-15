#!/usr/bin/env bash
[[ -n "$_ALPHA_CHECKHEALTH_SH" ]] && return 0
_ALPHA_CHECKHEALTH_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/colorizer.sh"
source "$UTILS/icons.sh"
source "$UTILS/formats.sh"
source "$UTILS/yqtools.sh"
source "$UTILS/plugtools.sh"

dep_chk() {
 local path bin req=("yq" "tmux" "git" "ascii-image-converter" "tput")
 local opt=("pv" "fzf")
 section "Dependencies"
 for bin in "${req[@]}"; do
   if path=$(command -v "$bin"); then
     ok "$bin ($path)"  
   else
     err "${bin^} not found in PATH."
   fi
 done
 for bin in "${opt[@]}"; do
   if path=$(command -v "$bin"); then
     ok "$bin ($path)"  
   else
     warn "${bin^} not found in PATH."
   fi
 done
 if (( BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 3) )); then
   ok "bash ${BASH_VERSION%%(*}"
 else
   err "Bash 4 or later is required."
 fi
}

env_chk() {
 local theme
 section "Environment and Cache"
 if [[ -f "$CATALOG" ]] && yq_get "." "$CATALOG" &>/dev/null; then 
   ok "catalog.yaml found."
 else err "Catalog file not found."
 fi

 if [[ -d "$PLUGINS_D" ]]; then ok 
 else err "Plugins directory not found."
 fi

 if [[ -d "$A_CACHE" ]]; then
   [[ -f "$A_CACHE/highlights.yaml" ]] && yq_get "." "$A_CACHE/highlights.yaml" &>/dev/null 
   theme="$(head -n1 "$A_CACHE/highlights.yaml")"
   ok "highlights.yaml theme: $theme."
 fi
}

plug_chk() {
 section "Plugins"
 :
}

main () {
 :
}
