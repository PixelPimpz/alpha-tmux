#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

main() {
  local tpm_bin
  for loc in "$HOME/.config/tmux/plugins/tpm/bin/update_plugins" "$HOME/.tmux/plugins/tpm/bin/update_plugins"; do
    [[ -x "$loc" ]] && { tpm_bin="$loc"; break; }
  done

  if [[ -z "$tpm_bin" ]]; then
    echo ""
    say "${ACCENTC}Error: TPM update_plugins binary not found.${RESET}"
    pause -b
    exit 1
  fi

  echo ""
  say "${HEADERC}Updating all TPM plugins...${RESET}\n"
  "$tpm_bin" all

  echo ""
  say "${SUCCESSC}✔ Reloading tmux configuration...${RESET}\n"
  tmux source-file "${TMUX_CONFIG:-$HOME/.config/tmux/tmux.conf}" 2>/dev/null

  pause -b "Done. Press any key to return to main menu... "
}

main
