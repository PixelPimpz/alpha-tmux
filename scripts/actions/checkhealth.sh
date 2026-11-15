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
 local theme cnt
 section "Environment and Cache"
 if [[ -f "$CATALOG" ]] && yq_get "." "$CATALOG" &>/dev/null; then 
   ok "Plugin Catalog: OK."
 else err "Plugin catalog file not found."
 fi

 if [[ -d "$PLUGINS_D" ]]; then ok "Plugins Directory: OK"
 else err "Plugins directory not found."
 fi

 if [[ -d "$A_CACHE" ]]; then
   if [[ -f "$A_CACHE/highlights.yaml" ]] && yq_get "." "$A_CACHE/highlights.yaml" &>/dev/null; then
   theme="$(head -n1 "$A_CACHE/highlights.yaml")"
   ok "Theme file OK: ${theme#*: }."
 else
   warn "Theme file not found."
   fi
   cnt="$( find "$A_CACHE" -maxdepth 1 -type f ! -name 'highlights.yaml' ! -name 'state_*.yaml' | wc -l)" 
   ok "Plugin cache: ${cnt} file(s)"
 fi
}

plug_chk() {
  local plugd plug enabled start draw plugc=0
  section "Plugins"
  for plugd in "${PLUGINS_D}"/*; do
    [[ -d "$plugd" ]] || continue
    (( plugc++ ))
    plug="${plugd##*/}"
    if [[ ! -f "$plugd/plugin.yaml" ]]; then
      err "$plugd/plugin.yaml not found"
      continue
    else
      enabled="$(get_opt "$plug" "enabled" "ON")"
      start="$(get_opt "$plug" "start" "init.sh")"
      draw="$(get_opt "$plug" "draw" "${plug}_draw")"
      [[ -f "$plugd/$start" ]] || { err "${plug^}: ${draw}() not found in $start"; continue; }
      if grep -qE "^[[:space:]]*${draw}[[:space:]]*\(\)" "$plugd/$start" >/dev/null; then
        ok "$plug (enabled: $enabled)"
      else
        err "${plug^} not enabled."
      fi
    fi
  done
  (( plugc == 0 )) && warn "No plugins installed." 
}

main () {
  ac
  center "alpha-tmux: checkhealth" "$HEADERC"
  dep_chk
  env_chk
  plug_chk
  pause -b "Press any key to continue."
}

 [[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"
