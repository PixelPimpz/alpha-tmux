#!/usr/bin/env bash
[[ -n "$_ALPHA_NAVIGATOR_SH" ]] && return 0
_ALPHA_NAVIGATOR_SH=1

# key capture to distinguish between plain [ESC] and \e[something
cap_key() {
  local _k _rest _out
  if ! IFS= read -rsn1 _k 2>/dev/null; then
    printf -v "${1:-RESULT}" "ESC"
    return 1
  fi
  _out="$_k"
  if [[ "$_k" == $'\x1b' ]]; then
    IFS= read -rsn2 -t 0.05 _rest
    case "$_rest" in
      "[A"|"OA") _out="UP";;
      "[B"|"OB") _out="DOWN";;
      "[C"|"OC") _out="RIGHT";;
      "[D"|"OD") _out="LEFT";;
              *) _out="ESC";;
    esac
  elif [[ -z "$_k" || "$_k" == $'\n' || "$_k" == $'\r' ]]; then
    _out="ENTER"
  elif [[ "$_k" == " " ]]; then
    _out="SPACE"
  fi
  printf -v "${1:-RESULT}" "%s" "$_out"
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
