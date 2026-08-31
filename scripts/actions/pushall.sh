#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
CONF="$PLUGIN_ROOT/config/settings.yaml"

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/utils/gitools.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

main() {
  local projects icon
  projects="$( get_projects )"
  [[ -d "$projects" ]] && error "Projects dir not found."
  for f in "${projects}"*; do
    if [[ "$(is_git "$f")" != "false" && "$(is_dirty "$f")" != "clean" ]]; then
      icon="$(get_icon "pass")"
    fi
  done
}

get_projects() {
  local projects
  projects="$( yq  eval '.Profiles[] | select(.name == "Default") | .projects' "$CONF" )"
  [[ ! "$projects" ]] && exit 1
  printf "%s\n" "$projects"
}

main
