#!/usr/bin/env bash
[[ -n "$_ALPHA_BREADCRUMBS_SH" ]] && return 0
_ALPHA_BREADCRUMBS_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"


source "$PLUGIN_ROOT/scripts/utils/formats.sh" 
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh" 
source "$PLUGIN_ROOT/scripts/utils/yqtools.sh" 

breadcrumbs() {
  local -n __stack="$1"
  local bcl="${#__stack[@]}"
  local glyph file title trail="" 
  printf -v glyph " \ue349 " 
  for (( i=0; i < bcl; i++ )); do
    file="${__stack[i]}"    
    title="$(yq e '.title // "alpha-TMUX"' "$file" )"
    # select hilighting based on $title's position in the loop-constructed
    # $trail
    case $(( ( bcl - 1 ) - i )) in 
      0 )
        trail+="${HEADERC}${title}${RESET} " ;;
      *)
        trail+="${TAGLINEC}${title}${RESET} ${BORDERC}${glyph}${RESET} " ;;
    esac
  done
  center  "$trail"
}
