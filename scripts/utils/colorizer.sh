#!/usr/bin/env bash
[[ -n "$_ALPHA_COLORIZER_SH" ]] && return 0
_ALPHA_COLORIZER_SH=1

source "$PLUGIN_ROOT/scripts/utils/profiler.sh"
source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"

_active_theme="$(get_active_theme 2>/dev/null)"
THEME="$PLUGIN_ROOT/themes/${_active_theme:-gruvbox-alpha-tmux}.yaml"
HIGHLIGHT="${XDG_CACHE_HOME:-$HOME/.cache}/alpha-tmux/highlights.yaml"

# use domain agnostic yq_get 
get_color() {
  hex2ansi "$(yq_get "$1" "$THEME")"
}
get_bg_color() {
  hex2ansi -bg "$(yq_get "$1" "$THEME")"
}

get_hlgroup() {
   yq eval '.Highlights[] | [.name, .hex, .ansi] | join("|")' "$HIGHLIGHT"
}

hex2ansi() {
  local mode="38"
  if [[ "$1" == "-bg" || "$1" == "--bg" ]]; then
    mode="48"
    shift
  fi

  local hexcolor Rd Gd Bd 
  hexcolor="${1:-#FFFFFF}"
  [[ ! "$hexcolor" =~ ^#[a-fA-F0-9]{6} ]] && fatal "Invalid HEX input."
  Rd="$((16#${hexcolor:1:2}))" #starting at index 1 to avoid the '#' in $hexcolor
  Gd="$((16#${hexcolor:3:2}))" 
  Bd="$((16#${hexcolor:5:2}))"
  printf '%s' "\e[${mode};2;${Rd};${Gd};${Bd}m"
}

loader() {
  local old 
  old="$( head -n1 "$HIGHLIGHT" 2>/dev/null | awk '{print $NF}')"
  [[ ! -f "$HIGHLIGHT" || "$old" != "$_active_theme" ]] && highlighter
  # 2. Read the file in 1 single pass and create all variables dynamically
  while IFS="|" read -r group hex ansi; do
    if [[ "$group" =~ _HEX$ ]]; then
      # If the variable group ends with _HEX, give it the raw hex code
      printf -v "$group" "%s" "$hex"
    else
      # Otherwise, it's an ANSI color code (e.g. BORDERC, HEADERC)
      printf -v "$group" "%s" "$ansi"
    fi
  done < <( get_hlgroup )
}

highlighter() {
  # will always overwrite if the file
  # exists otherwise will make a new one
  mkdir -p "${HIGHLIGHT%/*}"
  printf "# theme: %s\nHighlights:\n" "$_active_theme" > "$HIGHLIGHT"

  local group color hex ansi 
  while read -r group color; do
    hex="$(yq_get "$color" "$THEME")"
    [[ -z "$hex" || "$hex" == "null" ]] && continue
    if [[ "$color" =~ bg ]]; then
      ansi="$(hex2ansi -bg "$hex")"
    else
      ansi="$(hex2ansi "$hex")"
    fi
    cat <<- ENTRY >> "$HIGHLIGHT"
      - name: $group
        hex:  "$hex"
        ansi: "$ansi"
ENTRY
  done <<- EOF
	BORDER_HEX     .ui.border
	BG_HEX         .ui.button_bg
	HEADER_HEX     .ui.header
	TEXT_HEX       .palette.fg
	HEADERC        .ui.header
	MENUKEYC       .ui.menu_key
	TAGLINEC       .ui.tagline
	BORDERC        .ui.border
	BRACKETC       .ui.bracket
	KEYC           .ui.menu_key
	TEXTC          .ui.menu_text
	ICONC          .ui.menu_icon
	BUTTON_BGC     .palette.bg1
	ACCENTC        .ui.accent
	PROMPTC        .ui.accent
EOF
}

loader
export RESET=$'\033[0m'
