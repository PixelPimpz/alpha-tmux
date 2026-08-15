#!/usr/bin/env bash
[[ -n "$_ALPHA_RENDER_GRID_SH" ]] && return 0
_ALPHA_RENDER_GRID_SH=1

source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

# RENDER_GRID: Takes an array of button strings, calculates terminal column layout,
# frames with boxes, and centers output.

render_grid() {
  local Buttons=("$@")
  local buttonc="${#Buttons[@]}"
  [[ "$buttonc" -eq 0 ]] && return

  local clean_b0
  clean_b0=$(echo -e "${Buttons[0]}" | sed 's/\x1b\[[0-9;]*m//g')
  local buttonw="${#clean_b0}"
  local maxb="${MENU_COLS:-4}"
  local spacerw=2

  local rowc=$(( (buttonc + maxb - 1) / maxb ))
  local idx=0 rstring menu_text boxed_menu empty_btn
  menu_text=""

  for (( r = 0; r < rowc; r++ )); do
    rstring=""
    for (( c = 0; c < maxb; c++ )); do
      if (( idx < buttonc )); then
        if (( c > 0 )); then
          printf -v spacer "%*s" "$spacerw" ""
          rstring+="$spacer"
        fi
        rstring+="${Buttons[$idx]}"
        (( idx++ ))
      else
        printf -v empty_btn "%*s" "$buttonw" ""
        if (( c > 0 )); then
          printf -v spacer "%*s" "$spacerw" ""
          rstring+="$spacer"
        fi
        rstring+="$empty_btn"
      fi
    done

    if [[ -z "$menu_text" ]]; then
      menu_text="$rstring"
    else
      menu_text="$(printf "%s\n%s" "$menu_text" "$rstring")"
    fi
  done

  if command -v boxes &>/dev/null; then
    boxed_menu=$(echo "$menu_text" | boxes -d ansi | sed "s/│$/${BORDERC}│/")
  else
    boxed_menu="$menu_text"
  fi

  while read -r line; do
    center "$line" "$BORDERC"
  done <<< "$boxed_menu"
}
