#!/usr/bin/env bash
if [[ -z "$PLUGIN_ROOT" ]]; then
  if [[ -n "$ZSH_VERSION" ]]; then
    SCRIPT_PATH="$( readlink -f "${(%):-%x}" )"
  else
    SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
  fi
  PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
fi
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/yqtools.sh"
source "$UTILS/settings.sh"
source "$UTILS/icons.sh"
source "$UTILS/formats.sh"
source "$UTILS/errors.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/navigator.sh"

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
  local c1 c2 c3 c4 c5 c6
  read -r c1 c2 c3 c4 c5 c6 < <(yq eval "[.ui.header, .ui.tagline, .ui.accent, .ui.menu_key, .ui.menu_icon, .ui.button_bg] | join(\" \")" "$f" 2>/dev/null)
  printf "%s %s %s %s %s %s %s\033[0m" \
    "$(hex_bg "$c1")" \
    "$(hex_bg "$c2")" \
    "$(hex_bg "$c3")" \
    "$(hex_bg "$c4")" \
    "$(hex_bg "$c5")" \
    "$(hex_bg "$c6")"
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
  active_theme="$(get_active "theme")"
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

  local header_c tagline_c btn_bg btn_fg key_c border_c accent_c reset="\033[0m"
  header_c="$(hex_fg "$(yq_get ".ui.header" "$theme_file")")"
  tagline_c="$(hex_fg "$(yq_get ".ui.tagline" "$theme_file")")"
  btn_bg="$(hex_bg "$(yq_get ".ui.button_bg" "$theme_file")")"
  btn_fg="$(hex_fg "$(yq_get ".ui.menu_text" "$theme_file")")"
  key_c="$(hex_fg "$(yq_get ".ui.menu_key" "$theme_file")")"
  accent_c="$(hex_fg "$(yq_get ".ui.accent" "$theme_file")")"

  local pad
  printf -v pad "%*s" "$(get_margin 44)" ""

  printf "%s  %sHeader:%s   %balpha-TMUX%b\n" "$pad" "${MUTEDC}" "$reset" "$header_c" "$reset"
  printf "%s  %sTagline:%s  %bv1.0 • $(date '+%Y')%b\n\n" "$pad" "${MUTEDC}" "$reset" "$tagline_c" "$reset"
  printf "%s  %sButton:%s   %b 󰉉  Save Session  [%bS%b] %b\n\n" "$pad" "${MUTEDC}" "$reset" "$btn_bg" "$key_c" "$btn_fg" "$reset"

  printf "%s  %sPalette:%s  " "$pad" "${MUTEDC}" "$reset"
  local p_count=0
  while read -r pname phex; do
    [[ -z "$pname" ]] && continue
    printf "%b██%b %s " "$(hex_fg "$phex")" "$reset" "$pname"
    (( p_count++ >= 4 )) && break
  done < <(yq eval ".palette | to_entries | .[] | [.key, .value] | join(\" \")" "$theme_file" 2>/dev/null)
  printf "\n"

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

  set_active "theme" "$theme_id"

  ac
  printf "\n"
  say "${SUCCESSC}✔ Activated theme: ${TEXTC}${raw_name}${RESET}\n"
  sleep 0.8
}

main() {
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

main
