#!/usr/bin/env bash
# shellcheck disable=SC2034
# Msin Execution Loop / Event Loop
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/.." && pwd )"

# Load utilities
source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/builtin/breadcrumbs.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/Stack.sh"
source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"
source "$PLUGIN_ROOT/scripts/builtin/header_gen.sh"
source "$PLUGIN_ROOT/scripts/builtin/menu_gen.sh"

main () {
  local menu pressed comm current_menu depth
  local NAV_STACK=()
  menu="${1:-$PLUGIN_ROOT/lib/menu-main.yaml}" 
  [[ ! -f  $menu ]] && fatal "$menu not found"
  Stack_push NAV_STACK "$menu"
  #
  while true; do 
    Stack_peek NAV_STACK current_menu
    ac                                            # deep clear screen
    header_gen
    Stack_size NAV_STACK depth
    local trail=""
    (( depth > 1 )) && breadcrumbs NAV_STACK trail
    center " "
    menu_gen "$current_menu" "$trail"
    #
    read -r -n 1 -s pressed
    case "$pressed" in
      q|Q|"")
        exec "$SHELL" ;;
      b|B)
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
          else
            ac
            eval "$comm"
          fi
        else
          tmux status "Key $pressed not recognized."
        fi
        ;;
    esac
  done
}

main "$1"
