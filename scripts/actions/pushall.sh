#!/usr/bin/env bash
SCRIPT_SELF="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
SCRIPT_PATH="$SCRIPT_SELF"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
CONF="$PLUGIN_ROOT/config/settings.yaml"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/yqtools.sh"
source "$UTILS/profiler.sh"
source "$UTILS/icons.sh"
source "$UTILS/formats.sh"
source "$UTILS/errors.sh"
source "$UTILS/gitools.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/pop.sh"

render_list() {
  printf "\n"
  local MARGIN repo
  printf -v MARGIN "%*s" "${1:-8}" "" 
  for repo in "${projects%/}"/*; do
    [[ -d "$repo" ]] || continue
    is_git "$repo" &>/dev/null || continue

    if is_dirty "$repo" >/dev/null; then
      printf "%s%s%s   %s %s%s%s\n" "${MARGIN}" "${ACCENTC}" "$go" "$RESET" "$TEXTC" "${repo/$HOME/\~}" "$RESET"
    else
      printf "%s%s%s   %s %s%s%s\n" "${MARGIN}" "${SUCCESSC}" "$pass" "$RESET" "$TEXTC" "${repo/$HOME/\~}" "$RESET"
    fi
  done
  printf "\n"
}

pushall_view() {
  trap 'cursor on' INT EXIT TERM
  local key msg dir dirty=()
  local go pass projects

  go="$(get_icon "prog_up")"
  pass="$(get_icon "pass")"
  projects="$( get_projects )"

  [[ ! -d "$projects" ]] && error "Projects dir not found."

  # 1. Scan for dirty repos
  local linew line longest=0
  for repo in "${projects%/}"/*; do
    [[ -d "$repo" ]] || continue
    is_git "$repo" &>/dev/null || continue
    is_dirty "$repo" >/dev/null && dirty+=("$repo")

    # get the width of the longest line in the list
    line="${repo/$HOME/\~}"
    linew="${#line}"
    (( "$linew" > "$longest" )) && longest="$linew"
  done
  
  # 2. Render initial list
  local marginw
  marginw=$(get_margin $(( longest + 6 )) )
  render_list "$marginw"

  if (( "${#dirty[@]}" == 0 )); then
    say "${SUCCESSC}✔ All projects are up to date! Nothing to push.${RESET}\n"
    pause -b
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
  local tplugs=()
  for dir in "${dirty[@]}"; do
    push_repo "$dir" "$msg"
    ac
    render_list "$marginw"

    local plugd
    plugd="$(basename "$dir")"
    if [[ -d "$HOME/.config/tmux/plugins/$plugd" || -d "$HOME/.tmux/plugins/$plugd" ]]; then
      tplugs+=("$plugd")
    fi
  done

  # 5. Smart TPM Update & Reload
  if (( ${#tplugs[@]} > 0 )); then
    say "  ${PROMPTC}Updating TPM plugin(s): ${TEXTC}${tplugs[*]}${RESET}..."

    local tpm_bin
    for loc in "$HOME/.config/tmux/plugins/tpm/bin/update_plugins" "$HOME/.tmux/plugins/tpm/bin/update_plugins"; do
      [[ -x "$loc" ]] && { tpm_bin="$loc"; break; }
    done

    if [[ -n "$tpm_bin" ]]; then
      "$tpm_bin" "${tplugs[@]}" >/dev/null 2>&1
    fi

    say "  ${SUCCESSC}✔ Reloaded tmux configuration!${RESET}\n"
    tmux source-file "${TMUX_CONFIG:-$HOME/.config/tmux/tmux.conf}" 2>/dev/null
  fi

  say "  ${SUCCESSC}✔ All projects pushed!${RESET}\n"
  pause -b "Done. Press any key to return to main menu... "
  cursor "on"
  return 0
}

main() {
  if [[ "$1" == "view" ]]; then
    pushall_view
    return
  fi

  local projects
  projects="$( get_projects )"
  if [[ ! -d "$projects" ]]; then
    pu_toast -t "Sync All" -d 2.0 "Projects dir not found."
    exit 1
  fi

  local sample_lines=()
  sample_lines+=("Sync All Projects" "")
  for repo in "${projects%/}"/*; do
    [[ -d "$repo" ]] || continue
    is_git "$repo" &>/dev/null || continue
    sample_lines+=("    ✔   ${repo/$HOME/\~}")
  done
  sample_lines+=("" "Push dirty project(s)? [Y]/[n]" "Done. Press any key to return to main menu... ")

  local w h
  read -r w h < <( popsizer "${sample_lines[@]}" )
  (( w < 54 )) && w=54
  (( h < 12 )) && h=12

  popped "" "Sync All Projects" "d" "$w" "$h" "$SCRIPT_SELF" view
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
