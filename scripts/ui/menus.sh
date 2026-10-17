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

  # Check in-memory registry first
  if [[ -n "${ACTIVE_MENU_BTNS["${KEY}_name"]}" ]]; then
    BTN[name]="${ACTIVE_MENU_BTNS["${KEY}_name"]}"
    BTN[comm]="${ACTIVE_MENU_BTNS["${KEY}_comm"]}"
    BTN[icon]="${ACTIVE_MENU_BTNS["${KEY}_icon"]}"
    BTN[state]="${ACTIVE_MENU_BTNS["${KEY}_state"]}"
    BTN[msg]="${ACTIVE_MENU_BTNS["${KEY}_msg"]}"
    BTN[alt_comm]="${ACTIVE_MENU_BTNS["${KEY}_alt_comm"]}"
    BTN[stay]="${ACTIVE_MENU_BTNS["${KEY}_stay"]}"
    BTN[key]="$KEY"
    return 0
  fi

  # Fallback query directly via yqtools helper if not cached
  [[ -f "$file" ]] || return 1
  local k v
  while IFS="=" read -r k v; do
    [[ -n "$k" ]] && BTN["$k"]="$v"
  done < <(yq_button_by_key "$KEY" "$file")

  if (( ${#BTN[@]} > 0 )); then
    BTN[if]="${BTN[if]:-true}"
    BTN[state]="enabled"
    return 0
  fi
  return 1
}

format_button() {
  local badge="$1" name="$2" icon="$3" state="${4:-enabled}" max="${5:-0}"
  local glyph
  glyph="$(get_icon "$icon")"

  local c_icon="$ICONC" c_text="$TEXTC" c_brack="$BRACKETC" c_key="$KEYC"
  if [[ "$state" == "dimmed" ]]; then
    c_icon="$MUTEDC"
    c_text="$MUTEDC"
    c_brack="$MUTEDC"
    c_key="$MUTEDC"
  elif [[ "$state" == "toast" ]]; then
    c_icon="$MUTEDC"
    c_text="$TEXTC"
    c_brack="$BRACKETC"
    c_key="$ACCENTC"
  elif [[ "$state" == "install" ]]; then
    c_icon="$ACCENTC"
    c_text="$TEXTC"
    c_brack="$BRACKETC"
    c_key="$GOLDC"
  fi

  local lpad=""
  (( ${#badge} == 1 )) && lpad=" "

  printf "%s %s%s[%s%s%s] %s%-${max}s  %s%s %s" \
    "$BUTTON_BGC" \
    "$lpad" \
    "$c_brack" \
    "$c_key" "$badge" \
    "$c_brack" \
    "$c_text" "$name" \
    "$c_icon" "$glyph" \
    "$RESET"
}

# shellcheck disable=SC2153
make_button() {
  local KEY="$1" max="${2:-0}" file="${3:-$PLUGIN_ROOT/config/menus/main.yaml}"
  load_button "$KEY" "$file" || return 1
  format_button "${BTN[key]}" "${BTN[name]}" "${BTN[icon]}" "${BTN[state]:-enabled}" "$max"
}

## -----------------------------------------------------------------
# MENUS responsible for generating the main/base alpha-tmux menu
## -----------------------------------------------------------------
menus() {
  local menu="${1:-$PLUGIN_ROOT/config/menus/main.yaml}"
  local title="$2"
  local depth="${3:-1}"

  declare -gA ACTIVE_MENU_BTNS=()
  declare -gA ACTIVE_MENU_META=()
  local -A GRID_CELL=()

  local num_cols=0
  num_cols=$(yq_len ".columns" "$menu")
  (( num_cols == 0 )) && return 1

  local auto_key=0 max_w=0 max_rows=0 has_multi_digit=0

  # Step 1: Pre-scan columns and buttons via yqtools, evaluate active/if/alt, assign auto-keys, and calculate max_w
  local -A BTN_NAME=() BTN_ICON=() BTN_BADGE=() BTN_STATE=()
  local -A COL_BTN_COUNTS=()

  for (( c = 0; c < num_cols; c++ )); do
    local num_btns
    num_btns=$(yq_len ".columns[$c].buttons" "$menu")
    local r=0

    for (( b = 0; b < num_btns; b++ )); do
      local -A BTN=()
      local k v
      while IFS="=" read -r k v; do
        [[ -n "$k" ]] && BTN["$k"]="$v"
      done < <(yq_button_props "$c" "$b" "$menu")

      [[ -z "${BTN[name]}" ]] && continue

      # Filter: active: [0 | 1] / [false | true]
      local b_active="${BTN[active]:-1}"
      if [[ "$b_active" =~ ^(0|false)$ ]]; then
        continue
      fi

      # Evaluate runtime condition if:
      local b_state="enabled"
      local b_if="${BTN[if]:-true}"
      local b_alt="${BTN[alt]:-dimmed}"

      if [[ "$b_if" != "true" ]]; then
        if ! eval "$b_if" &>/dev/null; then
          case "$b_alt" in
            no-display|hide|hidden)
              continue ;;
            toast|warning|notice)
              b_state="toast" ;;
            install)
              b_state="install" ;;
            dimmed|disabled|*)
              b_state="dimmed" ;;
          esac
        fi
      fi

      # Expand dynamic name (e.g. $(get_option startup))
      local b_name="${BTN[name]}"
      eval "b_name=\"$b_name\""
      local len="${#b_name}"
      (( len > max_w )) && max_w="$len"

      # Determine badge & key
      local badge="${BTN[key]}"
      if [[ -z "$badge" || "$badge" == "null" ]]; then
        if [[ "$b_state" == "dimmed" ]]; then
          badge="-"
        else
          (( auto_key++ ))
          badge="$auto_key"
        fi
      fi

      (( ${#badge} > 1 )) && has_multi_digit=1

      # Register active key for io-loop
      if [[ "$b_state" != "dimmed" && "$badge" != "-" ]]; then
        ACTIVE_MENU_BTNS["${badge}_name"]="$b_name"
        ACTIVE_MENU_BTNS["${badge}_comm"]="${BTN[comm]}"
        ACTIVE_MENU_BTNS["${badge}_icon"]="${BTN[icon]}"
        ACTIVE_MENU_BTNS["${badge}_state"]="$b_state"
        ACTIVE_MENU_BTNS["${badge}_msg"]="${BTN[msg]}"
        ACTIVE_MENU_BTNS["${badge}_alt_comm"]="${BTN[alt_comm]}"
        ACTIVE_MENU_BTNS["${badge}_stay"]="${BTN[stay]:-0}"
      fi

      BTN_NAME["${c}_${r}"]="$b_name"
      BTN_ICON["${c}_${r}"]="${BTN[icon]}"
      BTN_BADGE["${c}_${r}"]="$badge"
      BTN_STATE["${c}_${r}"]="$b_state"

      (( r++ ))
    done

    COL_BTN_COUNTS["$c"]="$r"
    (( r > max_rows )) && max_rows="$r"
  done

  ACTIVE_MENU_META["has_multi_digit"]="$has_multi_digit"
  ACTIVE_MENU_META["total_keys"]="$auto_key"

  # Step 2: Format buttons and compute placeholder for empty slots
  local sample_btn clean_sample buttonw empty_btn
  sample_btn="$(format_button "1" "Sample Button" "gear" "enabled" "$max_w")"
  clean_sample=$(echo -e "$sample_btn" | sed -E 's/\x1b\[[0-9;]*m//g')
  buttonw="${#clean_sample}"
  printf -v empty_btn "%*s" "$buttonw" ""

  for (( c = 0; c < num_cols; c++ )); do
    local cnt="${COL_BTN_COUNTS["$c"]:-0}"
    for (( r = 0; r < cnt; r++ )); do
      GRID_CELL["${c}_${r}"]="$(format_button "${BTN_BADGE["${c}_${r}"]}" "${BTN_NAME["${c}_${r}"]}" "${BTN_ICON["${c}_${r}"]}" "${BTN_STATE["${c}_${r}"]}" "$max_w")"
    done
  done

  # Step 3: Build 2D grid row-by-row across columns
  local menu_text=""
  for (( r = 0; r < max_rows; r++ )); do
    local rstring=""
    for (( c = 0; c < num_cols; c++ )); do
      (( c > 0 )) && rstring+=" "
      rstring+="${GRID_CELL["${c}_${r}"]:-$empty_btn}"
    done

    if [[ -z "$menu_text" ]]; then
      menu_text="$rstring"
    else
      menu_text="$(printf "%s\n%s" "$menu_text" "$rstring")"
    fi
  done

  # Step 4: Draw box & print selection prompt
  boxer "$BORDERC" "$menu_text" "$title"
  if (( depth > 1 )); then
    center -n "Enter menu selection or press $(keys "ESC")${PROMPTC} to return to main menu." "$PROMPTC"
  else
    center -n "Enter menu selection or press $(keys "ENTER 󰌑")${PROMPTC} for a ${SHELL##*/} prompt." "$PROMPTC"
  fi
}
