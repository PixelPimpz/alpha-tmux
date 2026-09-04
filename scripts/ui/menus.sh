#!/usr/bin/env bash
[[ -n "$_ALPHA_MENUS_SH" ]] && return 0
_ALPHA_MENUS_SH=1

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/utils/icons.sh"
source "$PLUGIN_ROOT/scripts/utils/boxer.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

get_button() {
  local KEY file
  KEY="$1"
  local file="${2:-$PLUGIN_ROOT/config/menus/main.yaml}"
  yq e "(.Buttons[] // .columns[].buttons[]) | select(.key == \"$KEY\") | [.name, .icon, .key, .comm] | join(\"|\")" "$file"
}

make_button() {
  local KEY="$1" max="${2:-0}" file="${3:-$PLUGIN_ROOT/config/menus/main.yaml}"
  local name icon key comm glyph
  IFS="|" read -r name icon key comm < <(get_button "$KEY" "$file")
  glyph="$(get_icon "$icon")"

  printf "%s %s  %s%-${max}s  %s[%s%s%s] %s" \
  "$BUTTON_BGC" \
  "$ICONC$glyph" \
  "$TEXTC" \
  "$name" \
  "$BRACKETC" \
  "$KEYC" "$key" "$BRACKETC" \
  "$RESET"
}

## -----------------------------------------------------------------
# MENUS responsible for generating the main/base alpha-tmux menu
## -----------------------------------------------------------------
menus() {
  local max=0
  local menu="${1:-$PLUGIN_ROOT/config/menus/main.yaml}"
  local title="$2"

  # 1. Calculate max label width across buttons
  while read -r name; do
    local len="${#name}"
    (( len > max )) && max="$len"
  done < <(yq e '(.Buttons[].name // .columns[].buttons[].name)' "$menu")

  # 2. Get button width & placeholder for empty slots
  local sample_btn clean_sample buttonw empty_btn sample_key
  sample_key="$(yq e '(.Buttons[0].key // .columns[0].buttons[0].key)' "$menu")"
  sample_btn="$(make_button "$sample_key" "$max" "$menu")"
  clean_sample=$(echo -e "$sample_btn" | sed -E 's/\x1b\[[0-9;]*m//g')
  buttonw="${#clean_sample}"
  printf -v empty_btn "%*s" "$buttonw" ""

  # 3. Determine grid dimensions (columns and max rows)
  local num_cols max_rows=0
  num_cols=$(yq e '.columns | length' "$menu")

  for (( c = 0; c < num_cols; c++ )); do
    local colc
    colc=$(yq e ".columns[$c].buttons | length" "$menu")
    (( colc > max_rows )) && max_rows="$colc"
  done

  # 4. Build 2D grid row-by-row across columns
  local menu_text=""
  for (( r = 0; r < max_rows; r++ )); do
    local rstring=""
    for (( c = 0; c < num_cols; c++ )); do
      local key
      key=$(yq e ".columns[$c].buttons[$r].key" "$menu")

      (( c > 0 )) && rstring+=" "

      if [[ -n "$key" && "$key" != "null" ]]; then
        rstring+="$(make_button "$key" "$max" "$menu")"
      else
        rstring+="$empty_btn"
      fi
    done

    if [[ -z "$menu_text" ]]; then
      menu_text="$rstring"
    else
      menu_text="$(printf "%s\n%s" "$menu_text" "$rstring")"
    fi
  done

  # 5. Draw box & print selection prompt
  boxer "$BORDERC" "$menu_text" "$title"
  if [[ -n "$title" ]]; then
    center -n "Enter menu selection or press $(keys "b")${PROMPTC} or $(keys "ESC")${PROMPTC} to return to main menu." "$PROMPTC"
  else
    center -n "Enter menu selection or press $(keys "ENTER 󰌑")${PROMPTC} for a ${SHELL##*/} prompt." "$PROMPTC"
  fi
}

menu_gen() { menus "$@"; }
