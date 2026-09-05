#!/usr/bin/env bash
# shellcheck disable=SC2034
# Msin Execution Loop / Event Loop
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
export PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/.." && pwd )"
export ACTIONS="$PLUGIN_ROOT/scripts/actions"

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
        comm="$(yq eval "(.Buttons[] // .columns[].buttons[]) | select(.key == \"$pressed\") | .comm" "$current_menu")"
        popup_size="$(yq eval "(.Buttons[] // .columns[].buttons[]) | select(.key == \"$pressed\") | .popup" "$current_menu")"
        btn_name="$(yq eval "(.Buttons[] // .columns[].buttons[]) | select(.key == \"$pressed\") | .name" "$current_menu")"
        eval "target=\"$comm\""
        if [[ -n "$target" && "$target" != "null" ]]; then
          if is_yaml "$target"; then
            Stack_push NAV_STACK "$target"
          elif [[ -n "$popup_size" && "$popup_size" != "null" ]]; then
            boxed "$target" "$btn_name" "$popup_size"
            unset _ALPHA_COLORIZER_SH
            source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"
          else
            cursor on 
            ac
            eval "$comm"
            cursor off
          fi
        else
          tmux status "Key $pressed not recognized."
        fi
        ;;
    esac
  done
}

main "$1"
