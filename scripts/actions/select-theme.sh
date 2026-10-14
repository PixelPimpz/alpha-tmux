#!/usr/bin/env bash
# shellcheck disable=SC2153
SCRIPT_SELF="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
SCRIPT_PATH="$SCRIPT_SELF"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/yqtools.sh"
source "$UTILS/profiler.sh"
source "$UTILS/icons.sh"
source "$UTILS/formats.sh"
source "$UTILS/errors.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/navigator.sh"
source "$UTILS/pop.sh"

MENU=()

hex_fg() {
  local h="${1#\#}"
  printf "\033[38;2;%d;%d;%dm" "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))"
}

hex_bg() {
  local h="${1#\#}"
  printf "\033[48;2;%d;%d;%dm" "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))"
}

make_swatch() {
  local f="$1"
  local c1 c2 c3 c4 c5 c6 ico
  ico="$(get_icon "swatch")"
  read -r c1 c2 c3 c4 c5 c6 < <(yq eval "[.ui.header, .ui.tagline, .ui.accent, .ui.menu_key, .ui.menu_icon, .ui.button_bg] | join(\" \")" "$f" 2>/dev/null)
  printf "%s%s %s%s %s%s %s%s %s%s %s%s\033[0m" \
    "$(hex_fg "$c1")" "$ico" \
    "$(hex_fg "$c2")" "$ico" \
    "$(hex_fg "$c3")" "$ico" \
    "$(hex_fg "$c4")" "$ico" \
    "$(hex_fg "$c5")" "$ico" \
    "$(hex_fg "$c6")" "$ico"
}

is_light() {
  local f="$1"
  local t
  t="$(yq eval '.theme' "$f" 2>/dev/null)"
  [[ "$t" =~ (light|dawn|latte) ]] && return 0
  return 1
}

load_themes() {
  local active_theme ico_moon ico_sun ico_star
  active_theme="$(get_option "theme")"
  ico_moon="$(get_icon "moon")"
  ico_sun="$(get_icon "sun")"
  ico_star="$(get_icon "active")"

  MENU=()
  for theme_file in "$PLUGIN_ROOT/themes"/*-alpha-tmux.yaml; do
    [[ -f "$theme_file" ]] || continue
    local fname theme_id raw_name mode_glyph mode_color is_active=0 swatch

    fname="$(basename "$theme_file")"
    theme_id="${fname%.yaml}"
    raw_name="$(basename "$theme_file" -alpha-tmux.yaml)"

    if is_light "$theme_file"; then
      mode_glyph="$ico_sun"
      mode_color="\033[38;2;250;189;47m" # yellow
    else
      mode_glyph="$ico_moon"
      mode_color="\033[38;2;131;165;152m" # medium blue
    fi

    swatch="$(make_swatch "$theme_file")"
    [[ "$theme_id" == "$active_theme" ]] && is_active=1

    # Record format: theme_id|raw_name|mode_glyph|mode_color|swatch|is_active|theme_file
    MENU+=("$theme_id|$raw_name|$mode_glyph|$mode_color|$swatch|$is_active|$theme_file")
  done
}

draw_menu() {
  local selected="${1:-0}"
  ac
  printf "\n"

  local count="${#MENU[@]}"
  local margin pad
  margin="$(get_margin 38)"
  printf -v pad "%*s" "$margin" ""

  center "${HEADERC}Select Color Theme${RESET}"
  printf "\n"

  local ico_star
  ico_star="$(get_icon "active")"

  for (( i = 0; i < count; i++ )); do
    local item="${MENU[$i]}"
    local theme_id raw_name mode_glyph mode_color swatch is_active theme_file
    IFS="|" read -r theme_id raw_name mode_glyph mode_color swatch is_active theme_file <<< "$item"

    local cursor="  "
    local name_style="${TEXTC}"
    if (( i == selected )); then
      cursor="${ACCENTC}▸ ${RESET}"
      name_style="${ACCENTC}\033[1m"
    fi

    local star=" "
    if (( is_active == 1 )); then
      star="\033[38;2;250;189;47m${ico_star}${RESET}"
    fi

    local num=$(( i + 1 ))

    printf "%s%b%b  ${BRACKETC}[${KEYC}%d${BRACKETC}]${RESET}  %b  %b%s${RESET}  %b%-18s${RESET}\n" \
      "$pad" "$cursor" "$star" "$num" "$swatch" "$mode_color" "$mode_glyph" "$name_style" "$raw_name"
  done

  # Bottom legend pinned 1 row above bottom
  local rows
  rows="$(tput lines)"
  printf "\033[%d;1H" $(( rows - 1 ))
  center -n "${MUTEDC}[↑/↓] Move  [1-$count] Jump  [ENTER] View  [SPACE] Pick  [ESC] Quit${RESET}"
}

show_preview() {
  local selected="$1"
  local item="${MENU[$selected]}"
  local theme_id raw_name mode_glyph mode_color swatch is_active theme_file
  IFS="|" read -r theme_id raw_name mode_glyph mode_color swatch is_active theme_file <<< "$item"

  ac
  center "${HEADERC}Theme Preview: ${TEXTC}${raw_name}${RESET}"
  printf "\n"

  local h_c tag_c acc_c key_c ico_c btn_c
  local ico_swatch
  ico_swatch="$(get_icon "swatch")"
  h_c="$(yq_get ".ui.header" "$theme_file")"
  tag_c="$(yq_get ".ui.tagline" "$theme_file")"
  acc_c="$(yq_get ".ui.accent" "$theme_file")"
  key_c="$(yq_get ".ui.menu_key" "$theme_file")"
  ico_c="$(yq_get ".ui.menu_icon" "$theme_file")"
  btn_c="$(yq_get ".ui.button_bg" "$theme_file")"

  local pad
  printf -v pad "%*s" "$(get_margin 28)" ""

  printf "%s  %s%-14s%s %b%s%s %s\n" "$pad" "${MUTEDC}" "Header:" "${RESET}" "$(hex_fg "$h_c")" "$ico_swatch" "${RESET}" "$h_c"
  printf "%s  %s%-14s%s %b%s%s %s\n" "$pad" "${MUTEDC}" "Tagline:" "${RESET}" "$(hex_fg "$tag_c")" "$ico_swatch" "${RESET}" "$tag_c"
  printf "%s  %s%-14s%s %b%s%s %s\n" "$pad" "${MUTEDC}" "Accent:" "${RESET}" "$(hex_fg "$acc_c")" "$ico_swatch" "${RESET}" "$acc_c"
  printf "%s  %s%-14s%s %b%s%s %s\n" "$pad" "${MUTEDC}" "Shortcut Key:" "${RESET}" "$(hex_fg "$key_c")" "$ico_swatch" "${RESET}" "$key_c"
  printf "%s  %s%-14s%s %b%s%s %s\n" "$pad" "${MUTEDC}" "Menu Icon:" "${RESET}" "$(hex_fg "$ico_c")" "$ico_swatch" "${RESET}" "$ico_c"
  printf "%s  %s%-14s%s %b%s%s %s\n" "$pad" "${MUTEDC}" "Button Bg:" "${RESET}" "$(hex_fg "$btn_c")" "$ico_swatch" "${RESET}" "$btn_c"

  local rows
  rows="$(tput lines)"
  printf "\033[%d;1H" $(( rows - 1 ))
  center -n "${PROMPTC}[ENTER] Apply Theme   ${MUTEDC}[ESC / b] Back to List${RESET}"

  local pkey
  while true; do
    cap_key pkey
    case "$pkey" in
      ENTER|SPACE|a|A)
        apply_theme "$selected"
        return 0
        ;;
      ESC|b|B|q|Q)
        return 1
        ;;
    esac
  done
}

apply_theme() {
  local selected="$1"
  local item="${MENU[$selected]}"
  local theme_id raw_name
  IFS="|" read -r theme_id raw_name _ <<< "$item"

  set_option "theme" "$theme_id"

  ac
  printf "\n"
  say "${SUCCESSC}✔ Activated theme: ${TEXTC}${raw_name}${RESET}\n"
  sleep 0.8
}

select_theme_view() {
  trap 'cursor on' EXIT INT TERM
  cursor off

  load_themes
  local selected=0
  local count="${#MENU[@]}"
  local key

  # Initialize cursor on currently active theme
  for (( i = 0; i < count; i++ )); do
    if [[ "${MENU[$i]}" =~ \|1\| ]]; then
      selected="$i"
      break
    fi
  done

  while true; do
    draw_menu "$selected"
    cap_key key || break

    case "$key" in
      UP|k|K|DOWN|j|J|[1-9])
        selected="$(nav_nxt "$selected" "$key" "$count")"
        ;;
      ENTER)
        if show_preview "$selected"; then
          break
        fi
        ;;
      SPACE|a|A)
        apply_theme "$selected"
        break
        ;;
      ESC|q|Q)
        break
        ;;
    esac
  done

  cursor on
  ac
}

main() {
  if [[ "$1" == "view" ]]; then
    select_theme_view
    return
  fi

  load_themes
  local legend="[↑/↓] Move  [1-${#MENU[@]}] Jump  [ENTER] View  [SPACE] Pick  [ESC] Quit"
  local sample_lines=()
  sample_lines+=("Select Color Theme" "")
  for item in "${MENU[@]}"; do
    local raw_name
    IFS="|" read -r _ raw_name _ <<< "$item"
    sample_lines+=("  [1]  󰄮 󰄮 󰄮 󰄮 󰄮 󰄮    $raw_name")
  done
  sample_lines+=("" "$legend")

  local w h
  read -r w h < <( popsizer "${sample_lines[@]}" )

  # Ensure minimum height 16 for preview detail view
  (( h < 16 )) && h=16

  popped "" "Select Color Theme" "d" "$w" "$h" "$SCRIPT_SELF" view
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
