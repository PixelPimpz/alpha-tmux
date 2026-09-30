#!/usr/bin/env bash
[[ -n "$_ALPHA_PU_BUTTONS_SH" ]] && return 0
_ALPHA_PU_BUTTONS_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/colorizer.sh"
source "$UTILS/navigator.sh"
source "$UTILS/formats.sh"

pu_buttons() {
  local idx cur def_idx p_width p_height labels=()
  def_idx="${1:-0}"; shift
  labels=("$@")
  cursor off
  p_width="$(tput cols)"
  p_height="$(( $(tput lines) - 1 ))"
  cur="$def_idx"
  
  button_row() {
    local label pad plain buttons=""
    for (( idx=0; idx<${#labels[@]}; idx++ )) do
      label="${labels[$idx]}"
      if [[ "$idx" == "$cur" ]]; then
        button="${ACCENTC}[ $label ]${RESET}"
      else
        button="${MUTEDC}[ $label ]${RESET}"
      fi
      buttons+="  $button"
    done
    plain="$(stripper "$buttons")"
    pad="$(( ( p_width - "${#plain}" ) / 2 ))"
    (( pad < 0 )) && pad=0
    printf "\033[%d;1H\033[K%*s%s" "$p_height" "$pad" "" "$buttons"
  }

  button_row
  while true; do 
    local key
    cap_key key
    case "$key" in 
      RIGHT|TAB|$'\t'|l)
        cur=$(( (cur + 1) % ${#labels[@]} ))
        button_row ;;
      LEFT|h)
        cur=$(( (cur - 1 + ${#labels[@]}) % ${#labels[@]} ))
        button_row ;;
      ENTER)
        cursor on
        return "$cur" ;;
      ESC|q)
        cursor on
        return 1 ;;
    esac
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  "$@"
fi
