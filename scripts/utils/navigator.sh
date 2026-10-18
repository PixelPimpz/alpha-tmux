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

  case "$_k" in
    $'\x1b')
      IFS= read -rsn2 -t 0.05 _rest
      case "$_rest" in
        "[A"|"OA") _out="UP" ;;
        "[B"|"OB") _out="DOWN" ;;
        "[C"|"OC") _out="RIGHT" ;;
        "[D"|"OD") _out="LEFT" ;;
        *)         _out="ESC" ;;
      esac ;;
    ""|$'\n'|$'\r')
      _out="ENTER" ;;
    " ")
      _out="SPACE" ;;
    $'\t')
      _out="TAB" ;;
    *)
      _out="$_k" ;;
  esac

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

grid_nav() {
  local cur="$1" key="$2"
  local total="${ACTIVE_MENU_META[total_keys]:-1}"
  local num_cols="${ACTIVE_MENU_META[num_cols]:-1}"
  local c="${ACTIVE_MENU_META["key_${cur}_col"]:-0}"
  local r="${ACTIVE_MENU_META["key_${cur}_row"]:-0}"
  local nxt="$cur"

  case "$key" in
    DOWN|j|J)
      nxt=$(( cur < total ? cur + 1 : 1 )) ;;
    UP|k|K)
      nxt=$(( cur > 1 ? cur - 1 : total )) ;;
    RIGHT|l|L|TAB|LEFT|h|H)
      local dir=1
      [[ "$key" =~ ^(LEFT|h|H)$ ]] && dir=-1
      local step nc nr cand
      for (( step = 1; step < num_cols; step++ )); do
        nc=$(( (c + step * dir + num_cols) % num_cols ))
        for (( nr = r; nr >= 0; nr-- )); do
          cand="${ACTIVE_MENU_META["cell_${nc}_${nr}"]}"
          if [[ -n "$cand" ]]; then
            nxt="$cand"
            break 2
          fi
        done
      done ;;
  esac
  printf "%s\n" "$nxt"
}
