#!/usr/bin/env bash
[[ -n "$_ALPHA_PU_INPUT_SH" ]] && return 0
_ALPHA_PU_INPUT_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/navigator.sh"
source "$UTILS/pop.sh"

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

  popped "" "$title" "d" "$w" "$h" "$UTILS/pop/pu_input.sh" pu_input_view "$msg" "$init" "${labels[@]}"
  
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
    printf "\033[${inp_row};${pad}H${BUTTON_BGC}${TEXTC} %-*s${RESET}" "$(( field_w - 1 ))" "$buffer"
    if [[ "$mode" == "input" ]]; then
      printf "\033[%d;%dH" "${inp_row}" "$(( pad + cursor_idx + 1 ))"
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
  draw_buttons
  draw_field

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
        TAB)
          if (( btn_idx + 1 >= ${#labels[@]} )); then
            mode="input"
            btn_idx=0
            draw_buttons
            draw_field
          else
            (( btn_idx++ ))
            draw_buttons
          fi ;;
        RIGHT)
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

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  "$@"
fi
