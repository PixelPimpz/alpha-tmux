#!/usr/bin/env bash
## -----------------------------------------------------------------
# MENU_GEN responsible for generating the main/base alpha-tmux menu
## -----------------------------------------------------------------
menu_gen() {
  local len max; max=0
  local button name icon key glyph 
  local menu Buttons=()
  menu="${1:-$PLUGIN_ROOT/lib/menu-main.yaml}"
# first find out how long the longest .name is 
  while read -r name; do
    len="${#name}"
    (( len > max )) && max="$len"
  done < <(yq '.Buttons[].name' "$menu")
  # all the variables involveed in 
  local buttonw buttonc maxb margin rowc roww spacer spacerw
  buttonw="${#button}"
  buttonc="${#Buttons[@]}"
  margin="4"
  roww=$(( $(tput cols) - ( margin * 2 ) ))
  maxb=$(( roww / buttonw ))
  (( maxb > 4 )) && maxb=4
  (( maxb < 1 )) && maxb=1
  if (( maxb > 1 )); then
    spacerw=$(( ( roww - ( buttonw * maxb )) / ( maxb - 1 )))
  else
    spacerw=0
  fi
  rowc=$(( buttonc / maxb )) 
  if (( ( buttonc % maxb ) > 0 )); then
    (( rowc += 1 ))
  fi
  #
  local idx rstring menu_text boxed_menu
  idx=0
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
      fi
    done
    # 1. Accumulate rows into menu_text (instead of calling center)
    if [[ -z "$menu_text" ]]; then
      menu_text="$rstring"
    else
      menu_text="$(printf "%s\n%s" "$menu_text" "$rstring")"
    fi
  done
  # 2. Frame the accumulated grid with boxes and center the box
  if command -v boxes &>/dev/null; then
    boxed_menu=$(echo "$menu_text" | boxes -d ansi)
  else
    boxed_menu="$menu_text"
  fi
  while read -r line; do
    center "$line"
  done <<< "$boxed_menu"
  center "Enter menu selection or press [ENTER] for a ${SHELL##*/} promt"
}
