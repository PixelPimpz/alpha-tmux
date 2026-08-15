#!/usr/bin/env bash
[[ -n "$_ALPHA_ERRORS_SH" ]] && return 0
_ALPHA_ERRORS_SH=1

fatal() {
  local E
  E="${1:-Unknown Error.}"
  echo "FATAL: $E." 
  exit 1
}
