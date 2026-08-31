#!/usr/bin/env bash
[[ -n "$_ALPHA_FORMATS_SH" ]] && return 0
_ALPHA_FORMATS_SH=1

# FORMATS.sh (and layouts)------------------------
# helper functions pertainiong to how  things are 
# visually laid out.
# ------------------------------------------------
ICONS_FILE="$PLUGIN_ROOT/lib/icons.yaml"

center() {
  local ending=$'\n'
  if [[ "$1" == "-n" ]]; then
    ending=" "
    shift
  fi

  local row="$1" color="$2" roww termw pad plain
  plain=$(echo -e "$row" | sed 's/\x1b\[[0-9;]*m//g')
  roww="${#plain}"
  termw="$(tput cols)"
  pad=$(( ( termw - roww ) / 2 ))
  (( pad < 0 )) && pad=0

  if [[ -n "$color" ]]; then
    printf "%*s%s%s%s%s" "$pad" "" "$color" "$row" "$RESET" "$ending"
  else
    printf "%*s%s%s" "$pad" "" "$row" "$ending"
  fi
}
# UI Dialog & Popup Helpers -----------------------
say() {
  printf "  %b\n" "$*"
}

prompt() {
  local msg="$1" var="$2"
  read -rp "$msg" "${var?}" 
}

keys() {
  local K="$1"
  local OLD="${2:-$RESET}"
  printf "%s[%s%s%s]%s" "${BRACKETC}" "${KEYC}" "$K" "${BRACKETC}" "${OLD}"
}

pause() {
  local msg="${1:-Press any key to return to main menu... }"
  read -rp "  ${MUTEDC}${msg}${RESET}" -n 1 _
  echo ""
}
#
ac() {
  ## "AllClear" clear the terminal, clear scrollback and
  # put the cursor bacj at 0,0
  printf "\033[2J\033[H"
}
cursor() {
  case "${1:-on}" in 
    off|hide) printf "\033[?25l" ;;
    on|show|*) printf "\033[?25h" ;;
  esac
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

boxed() {
  local cmd title size w h  
  cmd="$1"
  title="${2:-alpha-TMUX }"
  size="$3"
  local sbox=("60" "14")
  local mbox=("70" "18")
  local lbox=("85%" "75%")
  case "$size" in 
    lbox|lg|large)
      w="${lbox[0]}"; h="${lbox[1]}" ;;
    mbox|md|medium)
      w="${mbox[0]}"; h="${mbox[1]}" ;;
    *) 
      w="${sbox[0]}"; h="${sbox[1]}" ;;
  esac
  # Launch popup with dynamic border (-S) and background (-s) from colorizer
  tmux display-popup -E -d "$PWD" -w "$w" -h "$h" -b rounded \
    -S "fg=${BORDER_HEX:-default}" \
    -s "bg=${BG_HEX:-default},fg=${TEXT_HEX:-#ebdbb2}" \
    -T "#[align=centre]#[fg=brightwhite,bold] $title " "$cmd"
}
