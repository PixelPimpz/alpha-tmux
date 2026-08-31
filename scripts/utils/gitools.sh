#!/usr/bin/env bash
[[ -n "$_ALPHA_GITOOLS_SH" ]] && return 0
_ALPHA_GITOOLS_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/utils/errors.sh"

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
