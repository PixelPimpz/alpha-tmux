#!/usr/bin/env bash

 SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
 PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
 UTILS="$PLUGIN_ROOT/scripts/utils"

## core uitls
source "$UTILS/errors.sh"
source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"

## Blueprints store in 
