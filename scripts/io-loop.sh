#!/usr/bin/env bash
# shellcheck disable=SC2034
# Msin Execution Loop / Event Loop
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/.." && pwd )"
ACTIONS="$PLUGIN_ROOT/scripts/actions"
UTILS="$PLUGIN_ROOT/scripts/utils"
[[ -d "$PLUGIN_ROOT/bin" ]] && PATH="$PLUGIN_ROOT/bin:$PATH"
export PLUGIN_ROOT ACTIONS UTILS PATH

# Load utilities
source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/ui/breadcrumbs.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/Stack.sh"
source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/ui/headers.sh"
source "$PLUGIN_ROOT/scripts/ui/menus.sh"

main () {
  local menu pressed comm current_menu depth
  local NAV_STACK=()
  menu="${1:-$PLUGIN_ROOT/config/menus/main.yaml}" 
  [[ ! -f  $menu ]] && fatal "$menu not found"
  Stack_push NAV_STACK "$menu"
  trap 'cursor on' EXIT INT TERM
  cursor off
  #
  while true; do 
    Stack_peek NAV_STACK current_menu
    ac                                            # deep clear screen
    header_gen
    Stack_size NAV_STACK depth
    local trail=""
    if (( depth > 1 )); then
      breadcrumbs NAV_STACK trail
    else
       trail="${ICONC}$(get_icon "folder")  ${TEXTC}~${PWD#"$HOME"}${RESET}"
    fi
    center " "
    menus "$current_menu" "$trail" "$depth"
    #
    read -r -n 1 -s pressed
    case "$pressed" in
      q|Q|"")
        cursor on
        ac 
        exec "$SHELL" ;;
      b|B|$'\e')
        Stack_size NAV_STACK depth 
        (( depth > 1 )) && Stack_pop NAV_STACK discarded
        ;;
      *)
        if ! load_button "$pressed" "$current_menu"; then
          tmux status "Key $pressed not recognized."
          continue
        fi

        if ! eval "${BTN[if]}"; then
          continue
        fi

        eval "target=\"${BTN[comm]}\""
        if [[ -n "$target" && "$target" != "null" ]]; then
          if is_yaml "$target"; then
            Stack_push NAV_STACK "$target"
          elif [[ -n "${BTN[popup]}" && "${BTN[popup]}" != "null" ]]; then
            popped "$target" "${BTN[name]}" "${BTN[popup]}"
            unset _ALPHA_COLORIZER_SH
            source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"
          else
            cursor on 
            ac
            eval "${BTN[comm]}"
            cursor off
          fi
        fi
        ;;
    esac
  done
}

main "$1"
