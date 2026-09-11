#!/usr/bin/env bash
[[ -n "$_ALPHA_STEPPER_SH" ]] && return 0
_ALPHA_STEPPER_SH=1

 SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
 PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

stepper() {
  local opts=() cur="$1"; shift
  opts=("$@")
  (( "${#opts[@]}" == 0 )) && return 1
  local idx=-1 i
  for i in "${!opts[@]}"; do
    if [[ "${opts[i]}" == "$cur" ]]; then
      idx="$i"
      break
    fi
  done
  if (( idx >= 0 )); then
    nxt_idx=$(( ( idx + 1 ) % ${#opts[@]} ))
  else
    nxt_idx=0
  fi
  printf "%s\n" "${opts[nxt_idx]}" 
} 
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  stepper "$@"
fi
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  "$@"
fi
