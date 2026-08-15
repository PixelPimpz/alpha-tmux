#!/usr/bin/env bash
# Msin Execution Loop / Event Loop
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/.." && pwd )"

# Load utilities
source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"

main () {
  local menu pressed comm
  menu="${1:-$PLUGIN_ROOT/lib/menu-main.yaml}" 
  [[ ! -f  $menu ]] && fatal "$menu not found"
  #
  while true; do 
    ac                                            # deep clear screen
    "$PLUGIN_ROOT/scripts/alpha-tmux.sh"
    #
    read -r -n 1 -s pressed
    [[ "$pressed" =~ q|Q || -z "$pressed" ]] && exec "$SHELL"  # drop into shell if Q,q or Enter pressed

    # get the comm(and) associated with the keypress from the current menu-*.yaml
    # check for valitity and if valid, run it
    comm="$(yq eval ".Buttons[] | select(.key == \"$pressed\") | .comm" "$menu")"
    if [[ -n "$comm" && "$comm" != "null" ]]; then 
      ac
      eval "$comm"
    else
      tmux status -R "Key $comm not recognized/"
    fi
  done
}

main "$1"
