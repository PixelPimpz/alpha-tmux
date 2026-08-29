#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/push.sh"
source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"

main() {
  local projects
  local yml="$PLUGIN_ROOT/config/settings.yaml"
  projects="$( yq 'yq e Profiles[] | select(.name == "Default") | .projects' "$yml" )"
  echo "$projects"
}

main
