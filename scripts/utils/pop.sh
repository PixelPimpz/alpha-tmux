#!/usr/bin/env bash
[[ -n "$_ALPHA_POP_SH" ]] && return 0
_ALPHA_POP_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/colorizer.sh"
source "$UTILS/navigator.sh"
source "$UTILS/formats.sh"

popped() {
  local cmd title size w h dw dh
  cmd="$1"
  title="${2:-alpha-TMUX}"
  size="$3"
  dw="$4"; dh="$5"
  local sbox=("60" "14")
  local mbox=("65" "18")
  local lbox=("85%" "75%")
  local dbox=("${dw}" "${dh}")
  
  case "$size" in 
    lbox|l|large)
      w="${lbox[0]}"; h="${lbox[1]}" ;;
    mbox|m|medium)
      w="${mbox[0]}"; h="${mbox[1]}" ;;
    sbox|s|small)
      w="${sbox[0]}"; h="${sbox[1]}" ;;
    dbox|d|dynamic)
      w="${dbox[0]}"; h="${dbox[1]}" ;;
    *)
      w="${sbox[0]}"; h="${sbox[1]}" ;;
  esac

  shift 5 2>/dev/null || shift $#
  if (( $# > 0 )); then
    tmux display-popup -E -d "$PWD" -w "$w" -h "$h" -b rounded \
      -S "fg=${BORDER_HEX:-default}" \
      -s "bg=${BG_HEX:-default},fg=${TEXT_HEX:-#ebdbb2}" \
      -T "#[align=centre]#[fg=brightwhite,bold] $title " "$@"
  else
    tmux display-popup -E -d "$PWD" -w "$w" -h "$h" -b rounded \
      -S "fg=${BORDER_HEX:-default}" \
      -s "bg=${BG_HEX:-default},fg=${TEXT_HEX:-#ebdbb2}" \
      -T "#[align=centre]#[fg=brightwhite,bold] $title " "$cmd"
  fi
}

pu_confirm() {
  local msg="${1:-Are you sure?}"
  local title="${2:-Confirm}"
  local def_idx="${3:-0}"
  local labels=("${@:4}")
  (( ${#labels[@]} == 0 )) && labels=("Yes" "No")

  local plain len w h
  plain="$(stripper "$msg")"
  len="${#plain}"
  w=$(( len + 8 ))
  (( w < 38 )) && w=38
  h=8

  popped "" "$title" "d" "$w" "$h" "$UTILS/pop.sh" pu_confirm_view "$msg" "$def_idx" "${labels[@]}"
  return $?
}

pu_confirm_view() {
  local msg="${1:-Are you sure?}"
  local def_idx="${2:-0}"
  local labels=("${@:3}")
  (( ${#labels[@]} == 0 )) && labels=("Yes" "No")

  ac
  printf "\033[3;1H"
  center "$msg"
  pu_buttons "$def_idx" "${labels[@]}"
}

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
      RIGHT|$'\t'|l)
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
