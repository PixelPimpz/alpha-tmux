#!/usr/bin/env bash
[[ -n "$_ALPHA_MENUS_SH" ]] && return 0
_ALPHA_MENUS_SH=1

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/utils/icons.sh"
source "$PLUGIN_ROOT/scripts/utils/boxer.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"
source "$PLUGIN_ROOT/scripts/utils/profiler.sh"

load_button() {
  local KEY="$1" file="${2:-$PLUGIN_ROOT/config/menus/main.yaml}"
  declare -gA BTN=()
  [[ -f "$file" ]] || return 1

  local k v
  while IFS="=" read -r k v; do
    [[ -n "$k" ]] && BTN["$k"]="$v"
  done < <(KEY="$KEY" yq e '.columns[].buttons[] | select(.key == env(KEY)) | to_entries | .[] | .key + "=" + .value' "$file")

  if (( ${#BTN[@]} > 0 )); then
    BTN[if]="${BTN[if]:-true}"
    return 0
  fi
  return 1
}

# shellcheck disable=SC2153
make_button() {
  local KEY="$1" max="${2:-0}" file="${3:-$PLUGIN_ROOT/config/menus/main.yaml}"
  load_button "$KEY" "$file" || return 1

  local name="${BTN[name]}"
  eval "name=\"$name\""
  local glyph
  glyph="$(get_icon "${BTN[icon]}")"

  local c_icon="$ICONC" c_text="$TEXTC" c_brack="$BRACKETC" c_key="$KEYC" badge="${BTN[key]}"
  if ! eval "${BTN[if]}"; then
    c_icon="$MUTEDC"
    c_text="$MUTEDC"
    c_brack="$MUTEDC"
    c_key="$MUTEDC"
    badge="-"
  fi

  printf "%s %s  %s%-${max}s  %s[%s%s%s] %s" \
    "$BUTTON_BGC" \
    "$c_icon$glyph" \
    "$c_text" \
    "$name" \
    "$c_brack" \
    "$c_key" "$badge" "$c_brack" \
    "$RESET"
}

## -----------------------------------------------------------------
# MENUS responsible for generating the main/base alpha-tmux menu
## -----------------------------------------------------------------
menus() {
  local max=0
  local menu="${1:-$PLUGIN_ROOT/config/menus/main.yaml}"
  local title="$2"
  local depth="${3:-1}"

  # 1. Calculate max label width across buttons
  while read -r name; do
    eval "name=\"$name\""
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
  if (( depth > 1 )); then
    center -n "Enter menu selection or press $(keys "b")${PROMPTC} or $(keys "ESC")${PROMPTC} to return to main menu." "$PROMPTC"
  else
    center -n "Enter menu selection or press $(keys "ENTER 󰌑")${PROMPTC} for a ${SHELL##*/} prompt." "$PROMPTC"
  fi
}
