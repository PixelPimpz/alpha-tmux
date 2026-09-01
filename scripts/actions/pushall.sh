#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
CONF="$PLUGIN_ROOT/config/settings.yaml"

source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/utils/gitools.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

get_projects() {
  local projects
  projects="$( yq  eval '.Profiles[] | select(.status == "active") | .projects' "$CONF" )"
  [[ ! "$projects" ]] && return 1
  printf "%s\n" "$projects"
}

main() {
  trap 'cursor on' INT EXIT TERM
  local projects skip go dirty=()
  go="$(get_icon "prog_up")"
  skip="$(get_icon "fail")"
  projects="$( get_projects )"
  
  [[ ! -d "$projects" ]] && error "Projects dir not found."
  
  for f in "${projects%/}"/*; do
    [[ -d "$f" ]] || continue
    is_git "$f" &>/dev/null || continue
    if is_dirty "$f" >/dev/null; then
      dirty+=("$f")
      icon="$go"
    else
      icon="$skip"
    fi
    repo="${f/$HOME/~}"
    printf "\t%s%-3s%s %s%s\n" "${MENUKEYC}" "$icon" "${TEXTC}" "$repo" "${RESET}"
  done

  # The doctor wants you to PUUUUUUSH!
  local key msg
  if (( "${#dirty[@]}" == 0 )); then
    say "${SUCCESSC}No repo with pending changes. Nothing to do.${RESET}"
    pause
    return 0
  fi
  read -rp "Commit message (optional) " msg
  cursor "off"
  read -rp "Push all dirty repos? [Y|n]" -n1 key 
  echo ""
  [[ "$key" =~ ^[nN]$ ]] && exit 1
  local dir
  for dir in "${dirty[@]}"; do
    push_repo "$dir" "$msg"
  done
  pause "Done. Press any key to return to main menu"
  cursor "on"
  return 0
}

main
