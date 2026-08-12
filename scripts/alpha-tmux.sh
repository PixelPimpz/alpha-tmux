#!/usr/bin/env bash
#
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/.." && pwd )"
IMAGE="$PLUGIN_ROOT/img/tmux_fp-outline.png"
TAGLINE="$( printf "Welcome to %s, %s! | %s" "$(tmux -V)" "$USER" "$(date "+%A, %b %d %Y")" )"
#
# ----- Helper functions
center() {
  local row roww termw pad
  row="$1"
  roww="${#row}"
  termw="$(tput cols)"
  pad=$(( ( termw - roww ) / 2 ))
  printf "%*s%s\n" "$pad" "" "$row"
}
#
is_session() {
  local bool
    if tmux ls >/dev/null 2>&1; then 
      bool="true"
    else bool="false"
  fi
  echo "$bool"
}
ac() {
# ac  = "AllClear. Used printf to clear the terminal and scrollback 
# and leave cursor atr top-left
  printf "\033[2J\033[H"
}
# ----- Generator functions 
banner_gen() {
  while read -r line; do
    center "$line"
  done <<< "$(ascii-image-converter -b -W 64 "$IMAGE" )"
  while read -r line; do
    center "$line"
  done <<< "$TAGLINE"
}
#
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
# now construct the buttons themselves
  while IFS="|" read -r name icon key; do
    glyph=$(yq ".icons[] | select(.name == \"$icon\") | .glyph" "$PLUGIN_ROOT/lib/icons.yaml")

    case "${#glyph}" in
      "4")
        icon="$(echo -e "\u$glyph")" ;;
      "5")
        icon="$(echo -e "\U$glyph")" ;;
      *)
        icon="?" ;;
    esac
    button="$(printf "%s  %-${max}s  [%s] %s" "$icon" "$name" "$key")"
    Buttons+=("$button")
  done < <(yq '.Buttons[] | [.name, .icon, .key] | join("|")' "$menu")
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
}
# ------ END of GENERATORS
main() {
  local menu
  menu="${1:-$PLUGIN_ROOT/lib/menu-main.yaml}"
  banner_gen
  center " "
  menu_gen "$menu"
 }
main
