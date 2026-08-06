#!/usr/bin/env bash
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
HEADER="$ROOT_DIR/lib/dharma.txt"
header_gen() {
  local termw linew pad
  termw="$(tput cols)"
  printf  "termw = %s\nbanner = %s\n" "$termw" "$HEADER"
  while read -r line;do 
    linew="${#line}"
    pad=$(( (termw - linew) / 2 ))
    printf "%*s%s\n" "$pad" "" "$line"
  done <<< "$(cat "$HEADER")"
}

header_gen
