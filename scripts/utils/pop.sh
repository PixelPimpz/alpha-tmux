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

pu_input() {
  local msg init title labels=()
  msg="${1:-Input:}"
  init="${2:-}"
  title="${3:-Input}"
  labels=("${@:4}")
  (( "${#labels[@]}" == 0 )) && labels=("Save" "Cancel")

  local msg_l val_l max_l
  msg_l="$(stripper "${msg}")"
  msg_l="${#msg_l}" 
  val_l="${init}"
  val_l="${#val_l}"
  max_l="$(( msg_l > val_l ? msg_l : val_l))"
  
  local w h
  w="$(( max_l + 12 ))"
  (( w < 48 )) && w=48
  (( w > 64 )) && w=64
  h=9

  popped "" "$title" "d" "$w" "$h" "$UTILS/pop.sh" pu_input_view "$msg" "$init" "${labels[@]}"
  
  local rc=$?
  if (( rc == 0 )); then
    tmux show-buffer -b alpha_input 2>/dev/null
    tmux delete-buffer -b alpha_input 2>/dev/null
    return 0
  fi
  return 1
}

pu_input_view() {
  local msg init labels=()
  msg="${1:-Input}"
  init="${2:-}"
  labels=("${@:3}")
  (( "${#labels[@]}" == 0 )) && labels=("Save" "Cancel")

  local p_width p_height field_w pad inp_row btn_row
  p_width="$(tput cols)"
  p_height="$(tput lines)"
  field_w="$(( p_width - 8 ))"
  pad="$(( ( p_width - field_w ) / 2 ))"
  inp_row=4
  btn_row="$(( p_height -1 ))"

  local mode buffer cursor_idx btn_idx
  mode="input"
  buffer="$init"
  cursor_idx="${#buffer}"
  btn_idx=0

  draw_field() {
    printf "\033[${inp_row};${pad}H${BUTTON_BGC}${TEXTC}%-*s${RESET}" "$field_w" "$buffer"
    if [[ "$mode" == "input" ]]; then
      printf "\033[${inp_row};$(( $pad + ${cursor_idx} ))H"
      cursor on
    else
      cursor off
    fi
  }

  draw_buttons() {
    local idx label plain b_pad buttons=""
    for (( idx=0; idx<"${#labels[@]}"; idx++ )) do
      label="${labels[$idx]}"
      if [[ "$mode" == "buttons"  && "$idx" == "$btn_idx" ]]; then
        button="${ACCENTC}[ $label ]${RESET}"
      else
        button="${MUTEDC}[ $label ]${RESET}"
      fi
      buttons+=" $button"
    done
    plain=$(stripper "$buttons")
    b_pad="$(( ( p_width - "${#plain}" ) / 2 ))"
    (( b_pad<0 )) && b_pad=0
    printf "\033[%d;1H\033[K%*s%s" "$btn_row" "$b_pad" "" "$buttons"
  }

  ac
  center "$msg"
  draw_field
  draw_buttons

  while true; do
    local key
    cap_key key
    if [[ "$key" == "ESC" ]]; then
      cursor on
      return 1
    fi
    case "$mode" in
      input)
        case "$key" in
          ENTER)
            tmux set-buffer -b alpha_input "$buffer"
            cursor on
            return 0 ;;
          TAB | DOWN)
            mode="buttons"
            draw_field
            draw_buttons ;;
          LEFT)
            (( cursor_idx > 0 )) && (( cursor_idx-- ))
            draw_field ;;
          RIGHT)
            (( cursor_idx < "${#buffer}" )) && (( cursor_idx++ ))
            draw_field ;; 
          $'\x7f' | $'\b')
            if (( cursor_idx > 0 )); then
              buffer="${buffer:0:cursor_idx-1}${buffer:cursor_idx}"
              (( cursor_idx-- ))
              draw_field
            fi ;;
          SPACE)
            if (( ${#buffer} < field_w - 2 )); then
              buffer="${buffer:0:cursor_idx} ${buffer:cursor_idx}"
              (( cursor_idx++ ))
              draw_field
            fi ;;
          *)
            if (( ${#key} == 1 && ${#buffer} < field_w - 2 )); then
              buffer="${buffer:0:cursor_idx}${key}${buffer:cursor_idx}"
              (( cursor_idx++ ))
              draw_field
            fi ;;
        esac ;;
      buttons)
      case "$key" in
        UP)
          mode="input"
          draw_buttons
          draw_field ;;
        TAB | RIGHT)
          btn_idx=$(( (btn_idx + 1) % ${#labels[@]} ))
          draw_buttons ;;
        LEFT)
          btn_idx=$(( (btn_idx - 1 + ${#labels[@]}) % ${#labels[@]} ))
          draw_buttons ;;
        ENTER)
          if (( "$btn_idx" == 0 )); then
            tmux set-buffer -b alpha_input "$buffer"
            cursor on
            return 0
          else 
            cursor on
            return 1
            fi ;;
        esac
      ;;
    esac
  done
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
