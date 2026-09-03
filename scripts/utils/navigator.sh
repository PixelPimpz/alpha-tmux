#!/usr/bin/env bash
[[ -n "$_ALPHA_NAVIGATOR_SH" ]] && return 0
_ALPHA_NAVIGATOR_SH=1

# key capture to distinguish between plain [ESC] and \e[something
cap_key() {
  local key rest out
  key="$1"
  read -rsn1 key 2>/dev/null
  out="$key"
  if [[ "$key" == $'\x1b' ]]; then
    IFS= read -rsn2 -t 0.05 rest
    case "$rest" in
      "[A"|"OA") out="UP";;
      "[B"|"OB") out="DOWN";;
      "[C"|"OC") out="RIGHT";;
      "[D"|"OD") out="LEFT";;
              *) out="ESC";;
    esac
  elif [[ -z "$key" || "$key" == $'\n' || "$key" == $'\r' ]]; then
    out="ENTER"
  elif [[ "$key" == " " ]]; then
    out="SPACE"
  fi
  printf -v "${1:-RESULT}" "%s" "$out"
}

# determines the next menu item to select|highlight
nav_nxt() {
  local cur key max nxt
  cur="$1"
  key="$2"
  max="$3"
  nxt="$cur" #this smells suspiciously like a linked list

  #adding the possibility of user having vim-style navigation
  local jump
  case "$key" in
    UP|k|K)
      (( cur > 0 )) && nxt=$(( cur - 1 )) ;;
    DOWN|j|J)
      (( cur < max - 1 )) && nxt=$(( cur + 1 )) ;;
    [1-9])
      jump=$(( key -1 ))
      (( jump < max )) && nxt="$jump" ;;
  esac
  printf "%d\n" "$nxt"
}
