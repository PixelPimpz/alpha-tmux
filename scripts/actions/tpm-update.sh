#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"
source "$PLUGIN_ROOT/scripts/utils/icons.sh"

## preload icons
ACTIVE="$(get_icon "active")"
PASS="$(get_icon "pass")"
FAIL="$(get_icon "fail")"

update_plugin() {
 local dir="$1"
 local name="${dir##*/}"
 local out res
 out="$(cd "$dir" && GIT_TERMINAL_PROMPT=0 git pull 2>&1)"
 res=$?

 if (( res != 0 )); then
   printf "  %-30s %s %s\n" "[$name]" "$FAIL" "${FAILC}Update failed.${RESET}"
 elif [[ "$out" == *"Already up to date"* || "$out" == *"Already up-to-date."* ]]; then
   printf "  %-30s %s %s\n" "[$name]" "$ACTIVE" "${MUTEDC}Already Up To Date${RESET}"
 else
   local chg
   chg="$(grep -oE '[0-9]+ files? changed' <<< "$out" || true)"
   [[ -z "$chg" ]] && chg="updated"
   printf "  %-30s %s %s\n" "[$name]" "$PASS" "${SUCCESSC}Update Success! ($chg)${RESET}"
   git -C "$dir" submodule update --init --recursive &>/dev/null
 fi
}

main() {
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
