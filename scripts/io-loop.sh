#!/usr/bin/env bash
# Msin Execution Loop / Event Loop
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/.." && pwd )"
fatal() {
  local E
  E="${1:-Unknown Error.}"
  echo "$E Exiting"
  exit 1
}

main () {
  local menu pressed comm
  menu="${1:-$PLUGIN_ROOT/lib/menu-main.yaml}" 
  [[ ! -f  $menu ]] && fatal "$menu not found"
  while true; do 
    printf "\033[2J\033[H"
    "$PLUGIN_ROOT/scripts/alpha-tmux.sh"
    read -r -n 1 -s pressed
    if [[ $pressed =~ q|Q ]]; then
        printf "\033[2J\033[H"
        exit 0
    fi
    comm="$(yq eval ".Buttons[] | select(.key == \"$pressed\") | .comm" "$menu")"
    if [[ -n "$comm" && "$comm" != "null" ]]; then 
      printf "\033[2J\033[H"
      eval "$comm"
    else
      tmux status -R "Key $comm not recognized/"
    fi
  done
}

main "$1"
