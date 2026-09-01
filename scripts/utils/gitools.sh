#!/usr/bin/env bash
[[ -n "$_ALPHA_GITOOLS_SH" ]] && return 0
_ALPHA_GITOOLS_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"

is_dirty() {
  local dir changes
  dir="${1:-$PWD}"
  if ! is_git "$dir" >/dev/null 2>&1; then
    return 1
  fi
  changes="$( git -C "$dir" status --porcelain 2>/dev/null )"
  if [[ -n "$changes" ]]; then
    printf "%s\n" "$changes"
    return 0
  fi
  return 1
}

# returns the root folder of the git or false if not a git
is_git() {
  local dir groot
  dir="${1:-$PWD}"
  groot="$( git -C "$dir" rev-parse --show-toplevel 2>/dev/null )"
  if [[ -n "$groot" ]]; then
    printf "%s\n" "$groot"
    return 0
  fi
  return 1
}

get_branch() {
  local dir active
  dir="${1:-"$PWD"}"
  active="$(git -C "$dir" branch --show-current 2>/dev/null)"
  printf "%s\n" "$active"
}

push_repo() {
  local dir msg stamp active
  dir="${1:-"$PWD"}"
  msg="${2:-"Routine commit:" }" 
  msg="${msg} $(timestamp)"
  is_git "$dir" &>/dev/null || return 1
  active="$(get_branch "$dir")"
  
  # the business end. 
  git -C "$dir" add . &>/dev/null || return 1
  git -C "$dir" commit -m "$msg" >/dev/null || return 1
  git -C "$dir" push origin "$active" 2>/dev/null || return 1
  return 0
}
