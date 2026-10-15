#!/usr/bin/env bash
SCRIPT_SELF="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
SCRIPT_PATH="$SCRIPT_SELF"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/icons.sh"
source "$UTILS/pop.sh"

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

tpm_update_view() {
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

main() {
  if [[ "$1" == "view" ]]; then
    tpm_update_view
    return
  fi

  local pdir="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/plugins"
  [[ ! -d "$pdir" ]] && pdir="$HOME/.tmux/plugins"

  if [[ ! -d "$pdir" ]]; then
    pu_toast -t "TPM Update" -d 2.0 "TPM plugins directory not found."
    exit 1
  fi

  local plugins=()
  for p in "$pdir"/*; do
    [[ -d "$p/.git" ]] && plugins+=("${p##*/}")
  done

  if (( ${#plugins[@]} == 0 )); then
    pu_toast -t "TPM Update" -d 2.0 "No TPM plugins found."
    exit 0
  fi

  local sample_lines=()
  sample_lines+=("Updating all TPM plugins..." "")
  for p in "${plugins[@]}"; do
    sample_lines+=("    [$p]    ✔ Updated (0 files changed)")
  done
  sample_lines+=("" "Reloading tmux configuration..." "" "Done. Press any key to return to main menu... ")

  local w h
  read -r w h < <( popsizer "${sample_lines[@]}" )
  (( w < 58 )) && w=58
  (( h < 10 )) && h=10

  popped "" "TPM Update All" "d" "$w" "$h" "$SCRIPT_SELF" view
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
