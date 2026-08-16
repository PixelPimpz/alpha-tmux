#!/usr/bin/env bash
# hex to ansi for RGB colors in the Linux terminal
fatal(){
  local E
  E="${1:-Unspecified error}"
  echo "Error: $E"
  exit 1
}

main() {
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

  printf "\033[%d;2;%d;%d;%dm" "$mode" "$Rd" "$Gd" "$Bd"
} 
main "$@"
