#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"
source "$PLUGIN_ROOT/scripts/utils/icons.sh"

## preload icons
ICO_ACTIVE="${GOLDC}$(get_icon "active")${RESET}"
ICO_PASS="${SUCCESSC}$(get_icon "pass")${RESET}"
ICO_FAIL="${FAILC}$(get_icon "fail")${RESET}"

update_plugin() {
 local dir="$1"
 local name="${dir##*/}"
 local out res
 out="$(cd "$dir" && GIT_TERMINAL_PROMPT=0 git pull 2>&1)"
 res=$?

  if (( res != 0 )); then
    printf "%s%-20s %s %s\n" "$pad" "[$name]" "$ICO_FAIL" "${FAILC}Update failed.${RESET}"
  elif [[ "${out,,}" == *"up to date"* || "${out,,}" == *"up-to-date"* ]]; then
    printf "%s%-20s %s %s\n" "$pad" "[$name]" "$ICO_ACTIVE" "${MUTEDC}Up To Date${RESET}"
  else
    local chg
    chg="$(grep -oE '[0-9]+ files? changed' <<< "$out" || true)"
   [[ -z "$chg" ]] && chg="updated"
   printf "%s%-20s %s %s\n" "$pad" "[$name]" "$ICO_PASS" "${SUCCESSC}Updated ($chg)${RESET}"
   git -C "$dir" submodule update --init --recursive &>/dev/null
 fi
}

main() {
  local margin pad
  margin="$(get_margin 52)"
  printf -v pad "%*s" "$margin" ""
  
  local pdir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins"
  [[ ! -d "$pdir" ]] && pdir="$HOME/.tmux/plugins"

  if [[ ! -d "$pdir" ]]; then
    echo ""
    say "${ACCENTC}Error: TPM plugins directory not found.${RESET}"
    pause -b
    exit 1
  fi

  echo ""
  say "${HEADERC}Updating all TPM plugins...${RESET}\n"

  for p in "$pdir"/*; do
    [[ -d "$p/.git" ]] && update_plugin "$p" &
  done
  wait

  echo ""
  say "${SUCCESSC}✔ Reloading tmux configuration...${RESET}\n"
  tmux source-file "${TMUX_CONFIG:-$HOME/.config/tmux/tmux.conf}" 2>/dev/null

  pause -b "Done. Press any key to return to main menu... "
}

main
