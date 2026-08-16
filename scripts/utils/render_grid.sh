#!/usr/bin/env bash
[[ -n "$_ALPHA_RENDER_GRID_SH" ]] && return 0
_ALPHA_RENDER_GRID_SH=1

source "$PLUGIN_ROOT/scripts/utils/boxer.sh"

## -----------------------------------------------------------------
# RENDER_GRID: Formats an array of button strings into a multi-column
# grid layout, and passes the result to boxer for framing and centering.
## -----------------------------------------------------------------
render_grid() {
  local Buttons=("$@")
  local buttonc="${#Buttons[@]}"
  [[ "$buttonc" -eq 0 ]] && return

  local clean_b0
  clean_b0=$(echo -e "${Buttons[0]}" | sed -E 's/\x1b\[[0-9;]*m//g')
  local buttonw="${#clean_b0}"
  local maxb="${MENU_COLS:-4}"
  local spacerw=1

  local rowc=$(( (buttonc + maxb - 1) / maxb ))
  local idx=0 rstring menu_text="" empty_btn

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

  boxer "$BORDERC" "$menu_text"
}
