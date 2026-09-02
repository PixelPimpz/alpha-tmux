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

render_list() {
  printf "\n"
  for repo in "${projects%/}"/*; do
    [[ -d "$repo" ]] || continue
    is_git "$repo" &>/dev/null || continue

    if is_dirty "$repo" >/dev/null; then
      printf "  %s%-2s%s %s%s%s\n" "${ACCENTC}" "$go" "$RESET" "$TEXTC" "${repo/$HOME/\~}" "$RESET"
    else
      printf "  %s%-2s%s %s%s%s\n" "${SUCCESSC}" "$pass" "$RESET" "$TEXTC" "${repo/$HOME/\~}" "$RESET"
    fi
  done
  printf "\n"
}

main() {
  trap 'cursor on' INT EXIT TERM
  local key msg dir dirty=()
  local go pass projects

  go="$(get_icon "prog_up")"
  pass="$(get_icon "pass")"
  projects="$( get_projects )"

  [[ ! -d "$projects" ]] && error "Projects dir not found."

  # 1. Scan for dirty repos
  for repo in "${projects%/}"/*; do
    [[ -d "$repo" ]] || continue
    is_git "$repo" &>/dev/null || continue
    is_dirty "$repo" >/dev/null && dirty+=("$repo")
  done

  # 2. Render initial list
  render_list

  if (( "${#dirty[@]}" == 0 )); then
    say "${SUCCESSC}✔ All projects are up to date! Nothing to push.${RESET}\n"
    pause
    return 0
  fi

  # 3. Prompts
  prompt "  ${PROMPTC}Commit message (optional): ${RESET}" msg
  echo ""
  cursor "off"
  read -rp "  ${PROMPTC}Push ${#dirty[@]} dirty project(s)? $(keys "Y" "$PROMPTC")/$(keys "n" "$PROMPTC"): ${RESET}" -n1 key 
  echo ""
  [[ "$key" =~ ^[nN]$ ]] && exit 0

  # 4. Live update push loop!
  for dir in "${dirty[@]}"; do
    push_repo "$dir" "$msg"
    ac
    render_list
  done

  say "${SUCCESSC}✔ All projects pushed!${RESET}\n"
  pause "Done. Press any key to return to main menu... "
  cursor "on"
  return 0
}

main
