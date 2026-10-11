#!/usr/bin/env bash
main() {
  local chr="${1:-$( nf md-circle -g)}"
  local hex="${2:-#ffffff}"
  local side="${3:-F}"
  local r g b   
  case "$side" in
    f|F) side=38 ;;
    b|B) side=48 ;;
    *) exit 1 ;;
  esac
  R="$((16#${hex:1:2}))"
  G="$((16#${hex:3:2}))"
  B="$((16#${hex:5:2}))"
  printf "HEX: %s\nR: %d\nG: %d\nB: %d\n" "$hex" $R $G $B
  printf "\033[%d;2;%d;%d;%dm\"SAMPLE TXT\" \033[0m\n" $side $R $G $B  
  printf "\033[%d;2;%d;%d;%dm%s \033[0m\n" $side $R $G $B "$chr"
}
main "$@"
