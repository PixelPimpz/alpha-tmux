#!/usr/bin/env bash
[[ -n "$_ALPHA_PLUGMAN_SH" ]] && return 0
_ALPHA_PLUGMAN_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"
UI="$PLUGIN_ROOT/scripts/ui"
CONFIG="$PLUGIN_ROOT/config"

CATALOG="$CONFIG/catalog/yaml"

source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/icons.sh"
source "$UTILS/boxer.sh"
source "$UTILS/navigator.sh"
source "$UTILS/pop.sh"
source "$UTILS/plugtools.sh"
source "$UI/headers.sh"
source "$UI/menus.sh"

declare -gA NAV_GRID=() ACTION=() TARGET=()

left_menu(){
  local yaml="$PLUGIN_ROOT/config/menus/plugman.yaml"
  local cnt b k v
  LEFT_ITEMS=()
  cnt="$(yq_len ".columns[0].buttons" "$yaml")"
  for (( b = 0; b < cnt; b++ )); do
    local -A BTN=()
    while IFS="=" read -r k v; do
      [[ -n "$k" ]] && BTN["$k"]="$v"
    done < <(yq_button_props 0 "$b" "$yaml")
    [[ -n "${BTN[name]}" ]] && LEFT_ITEMS+=("${BTN[name]}|${BTN[icon]}|${BTN[comm]}")
  done
}

right_menu() {
  local pdir plug ui title ico state prop o_label o_ico values
  RIGHT_ITEMS=()
  for pdir in "$PLUGINS_D"/*; do
    [[ -f "$pdir/plugin.yaml" ]] || continue
    plug="$(basename "$pdir")"
    title="$(get_opt "$plug" "title" "$plug")"
    ico="$(get_opt "$plug" "icon" "plug")"
    state="$(get_opt "$plug" "enabled" "ON")"
    ui="$(get_opt "$plug" "ui" "")"

    local opts=()
    mapfile -t opts < <(yq_plug_opts "$pdir/plugin.yaml")

    if [[ -n "$ui" ]] || (( ${#opts[@]} > 1 )); then
      RIGHT_ITEMS+=("${title}: ${state}|${ico}|detail:plug_ui:${plug}|${plug}")
    elif (( ${#opts[@]} == 1 )); then
      IFS="|" read -r prop o_label o_ico values <<< "${opts[0]}"
      RIGHT_ITEMS+=("${o_label}$(get_opt "$plug" "$prop")|${o_ico:-$ico}|step_opt $plug $prop $values|${plug}")
    else
      RIGHT_ITEMS+=("${title}: ${state}|${ico}|step_opt $plug enabled ON OFF|${plug}")
    fi
  done
}

box_col() {
  local  col max_rows selected title max_w plain_title
  local -n items="$1"
  local -n col_text="$6"
  col="$2" max_rows="$3" 
  selected="$4" title="$5"
  plain_title="$(stripper "$title")"
  local min_w=$(( "${#plain_title}" - 4))
  max_w=$min_w
  for item in "${items[@]}"; do
  IFS="|" read -r name _ <<< "$item"
    (( "${#name}" > max_w )) && max_w="${#name}"
  done
  
  local blank_btn plain_blank blank_tile
  blank_btn="$(format_button "1" "Blank" "plug" "enabled" "$max_w" 0)"
  plain_blank="$(stripper "$blank_btn")"
  printf -v blank_tile "%s%*s%s" "$BUTTON_BGC" "${#plain_blank}" "" "$RESET"
  ## generate box content
  col_text=""
  local r name ico comm plug is_sel
  for (( r=0; r < max_rows; r++ )); do
    (( r > 0 )) && col_text+=$'\n'
    if (( r < "${#items[@]}" )); then
      (( KEY_IDX++ ))
      IFS="|" read -r name ico comm plug <<< "${items[$r]}"
      NAV_GRID["key_${KEY_IDX}_col"]="$col"
      NAV_GRID["key_${KEY_IDX}_row"]="$r"
      NAV_GRID["cell_${col}_${r}"]="$KEY_IDX"
      ACTION["$KEY_IDX"]="$comm"
      TARGET["$KEY_IDX"]="$plug"
      is_sel=$(( selected == KEY_IDX ? 1 : 0 ))
      col_text+="$( format_button "$KEY_IDX" "$name" "$ico" "enabled" "$max_w" "$is_sel" )"
    else
      col_text+="$blank_tile"
    fi
  done
}

plugman () {
  local selected="${1:-1}" mode_l="${2:-menu}" mode_r="${3:-normal}"
  NAV_GRID=() ACTION=() TARGET=()
  KEY_IDX=0

  local max_rows="${#LEFT_ITEMS[@]}"
  local title_l title_r text_l="" text_r=""
  (( "${#RIGHT_ITEMS[@]}" > max_rows )) && max_rows="${#RIGHT_ITEMS[@]}"
  title_l="${ICONC}$(get_icon "plug")  ${TEXTC}Plugin Manager${RESET}"
  title_r="${ICONC}$(get_icon "settings")  ${TEXTC}Installed Plugins${RESET}"
  if [[ "$mode_r" == "uninstall" ]]; then
    title_r="${WARNC}$(get_icon "package_remove")  Select Plugin to Uninstall${RESET}"
  fi

  box_col LEFT_ITEMS  0 "$max_rows" "$selected" "$title_l" text_l
  box_col RIGHT_ITEMS 1 "$max_rows" "$selected" "$title_r" text_r

  NAV_GRID["total_keys"]="$KEY_IDX"
  NAV_GRID["num_cols"]=2
  NAV_GRID["max_rows"]="$max_rows"

  local sel_col="${NAV_GRID["key_${selected}_col"]:-0}"
  local border_l="$BORDERC" border_r="$BORDERC"
  if (( sel_col == 0 )); then
    border_l="$ACCENTC"
  else
    border_r="$ACCENTC"
  fi
  [[ "$mode_r" == "uninstall" ]] && border_r="$WARNC"

  boxer -r 2 "$border_l" "$text_l" "$title_l"
  boxer -r 2 "$border_r" "$text_r" "$title_r"
}

main () {
  local selected=1 mode_l="menu" mode_r="normal" refresh=1 pressed comm key
  trap 'cursor on' EXIT INT TERM
  cursor off
  left_menu

  # event loop
  while true;  do
    if [[ "$refresh" == 1 ]]; then
      right_menu; ac
      header
      center " "
      printf "\033[s"
    else
      printf "\033[u"
    fi
    plugman "$selected" "$mode_l" "$mode_r"
    refresh=1
    cap_key pressed
    if [[ "$pressed" == "1" ]] && (( KEY_IDX >= 10 )); then
      if read -rt 0.25 -n 1 -s key && [[ "$key" =~ [0-9] ]]; then
        pressed="${pressed}${key}"
      fi
    fi
    case "$pressed" in
      UP|DOWN|LEFT|RIGHT|TAB|h|j|k|l|H|J|K|L)
        selected="$(grid_nav "$selected" "$pressed")"
        refresh=0
        continue ;;
      ESC|Q|q)
        [[ "$mode_r" == "uninstall" ]] && { mode_r="normal"; continue; }
        if [[ "$mode_l" != "menu" ]]; then 
          mode_l="menu"
          continue
        else
          return 0
        fi ;;
      IGNORE)
        refresh=0; continue
        ;;
      *)
        if [[ "$pressed" =~ ^(ENTER|SPACE)$ ]];then 
          pressed="$selected"
        fi
        comm="${ACTION[$pressed]}"
        if [[ -z "$comm" ]]; then 
          refresh=0
          continue 
        fi
        case "$comm" in
          step_opt*)
            eval "$comm" ;;
          mode:uninstall)
            mode_r="$( stepper "$mode_r" "normal" "uninstall")"
            ;;
          *)
            pu_toast -t "Plugman" -d 1.5 "TODO: $comm" ;;
        esac
    esac
  done
}


main "$@"
