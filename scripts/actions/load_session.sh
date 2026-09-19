#!/usr/bin/env bash
[[ -n "$_ALPHA_LOAD_SESSION_SH" ]] && return 0
_ALPHA_LOAD_SESSION_SH=1

 SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
 PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
 UTILS="$PLUGIN_ROOT/scripts/utils"
