#!/usr/bin/env bash
# Msin Execution Loop / Event Loop
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/.." && pwd )"
ACTIONS="$PLUGIN_ROOT/scripts/actions"
UTILS="$PLUGIN_ROOT/scripts/utils"
UI="$PLUGIN_ROOT/scripts/ui"
MENUS="$PLUGIN_ROOT/config/menus"

[[ -d "$PLUGIN_ROOT/bin" ]] && PATH="$PLUGIN_ROOT/bin:$PATH"
export PLUGIN_ROOT ACTIONS UTILS MENUS PATH

# Load utilities
source "$UTILS/pop.sh"
source "$UTILS/errors.sh"
source "$UTILS/formats.sh"
source "$UTILS/Stack.sh"
source "$UTILS/yqtools.sh"
source "$UI/breadcrumbs.sh"
source "$UI/headers.sh"
source "$UI/menus.sh"

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
    
    # READ INPUT
    read -r -n 1 -s pressed
    if [[ "${ACTIVE_MENU_META["has_multi_digit"]:-1}" == "1" && "$pressed" == "1" ]]; then
      # allow for multi-digit entry
      if read -rt 0.25 -n 1 -s key && [[ "$key" =~ [0-9] ]]; then
        pressed="${pressed}${key}"
      fi
    fi
    case "$pressed" in
      q|Q|"")
        cursor on
        ac 
        exec "$SHELL" ;;
      $'\e')
        Stack_size NAV_STACK depth 
        (( depth > 1 )) && Stack_pop NAV_STACK discarded
        ;;
      *)
        if ! load_button "$pressed" "$current_menu"; then
          tmux status "Key $pressed not recognized."
          continue
        fi

        case "${BTN[state]}" in
          dimmed)
            continue
            ;;
          toast)
            pu_toast -t "${BTN[name]}" -d 2.0 "${BTN[msg]:-Option is currently unavailable.}"
            continue
            ;;
          install)
            if [[ -n "${BTN[alt_comm]}" && "${BTN[alt_comm]}" != "null" ]]; then
              cursor on
              eval "${BTN[alt_comm]}"
              cursor off
            else
              pu_toast -t "${BTN[name]}" -d 2.0 "Install action not configured."
            fi
            continue
            ;;
          enabled|*)
            eval "target=\"${BTN[comm]}\""
            if [[ -n "$target" && "$target" != "null" ]]; then
              if is_yaml "$target"; then
                Stack_push NAV_STACK "$target"
              else
                cursor on 
                eval "${BTN[comm]}"
                local exit_c="$?"
                cursor off
                (( exit_c == 0 )) && [[ ! "${BTN[stay]:-0}" =~ ^(1|true)$ ]] && NAV_STACK=("$menu")
               fi
              unset _ALPHA_COLORIZER_SH
              source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"
            fi
            ;;
        esac
        ;;
    esac
  done
}

main "$1"
