#!/usr/bin/env bash
[[ -n "$_ALPHA_BREADCRUMBS_SH" ]] && return 0
_ALPHA_BREADCRUMBS_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"


source "$PLUGIN_ROOT/scripts/utils/formats.sh" 
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh" 
source "$PLUGIN_ROOT/scripts/utils/yqtools.sh" 

breadcrumbs() {
  local -n __stk="$1"
  local __bcl="${#__stk[@]}"
  local __glyph __file __title __trail="" 
  printf -v __glyph " \ue349 " 
  for (( i=0; i < __bcl; i++ )); do
    __file="${__stk[i]}"    
    __title="$(yq e '.title // "alpha-TMUX"' "$__file" )"
    # select hilighting based on $title's position in the loop-constructed
    # $trail
    case $(( ( __bcl - 1 ) - i )) in 
      0 )
        __trail+="${HEADERC}${__title}${RESET}" ;;
      *)
        __trail+="${TAGLINEC}${__title}${RESET}${BORDERC}${__glyph}${RESET}" ;;
    esac
  done

  if [[ -n "$2" ]]; then
    local -n __out_var="$2"
    __out_var="$__trail"
  else
    center "$__trail"
  fi
}
