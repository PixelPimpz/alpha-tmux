#!/usr/bin/env bash
# FORMATS.sh (and layouts)------------------------
# helper functions pertainiong to how  things are 
# visually laid out.
# ------------------------------------------------
ICONS_FILE="$PLUGIN_ROOT/lib/icons.yaml"
center() {
  local row="$1" color="$2" roww termw pad
  roww="${#row}"
  termw="$(tput cols)"
  pad=$(( ( termw - roww ) / 2 ))

  if [[ -n "$color" ]]; then
    printf "%*s%s%s%s\n" "$pad" "" "$color" "$row" "$RESET"
  else
    printf "%*s%s\n" "$pad" "" "$row"
  fi
}
#
ac() {
  ## "AllClear" clear the terminal, clear scrollback and
  # put the cursor bacj at 0,0
  printf "\033[2J\033[H"
}
#
show-icons() {
  if [[ ! -f "$ICONS_FILE" ]]; then
    echo "Error: Could not find icons.yaml at $ICONS_FILE" >&2
    exit 1
  fi

  while IFS="|" read -r name glyph; do
    case "${#glyph}" in
      "4") icon="$(echo -e "\u$glyph")" ;;
      "5") icon="$(echo -e "\U$glyph")" ;;
      *)   icon="?" ;;
    esac
    printf "%-15s %s\n" "$name:" "$icon"
  done < <(yq '.icons[] | [.name, .glyph] | join("|")' "$ICONS_FILE")
}
