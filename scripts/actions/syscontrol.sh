 #!/usr/bin/env bash
    SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
    PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
    UTILS="$PLUGIN_ROOT/scripts/utils"
    ACTIONS="$PLUGIN_ROOT/scripts/actions"

    source "$UTILS/pop.sh"

    main() {
      local action="$1"
      case "$action" in
        logout)
          pu_confirm "Log out '$USER' to login screen?" "Desktop Logout" 0 "Logout" "Cancel" || exit 1
          loginctl terminate-user "$USER"
          ;;
        save-logout)
          pu_confirm "Save session and log out '$USER'?" "Save & Logout" 0 "Save & Logout" "Cancel" || exit 1
          "$ACTIONS/save_session.sh" || exit 1
          loginctl terminate-user "$USER"
          ;;
        reboot)
          pu_confirm "Reboot the system now?" "System Reboot" 0 "Reboot" "Cancel" || exit 1
          systemctl reboot
      	  ;;
        bios)
          pu_confirm "Reboot into UEFI/BIOS setup?" "Reboot to EFI/BIOS" 0 "Reboot" "Cancel" || exit 1
          systemctl reboot --firmware-setup
          ;;
        soft-reboot)
          pu_confirm "Perform a userspace soft-reboot?" "Soft System Reboot" 0 "Soft Reboot" "Cancel" || exit 1
          systemctl soft-reboot
          ;;
        poweroff)
          pu_confirm "Power off the system now?" "Power Off" 0 "Power Off" "Cancel" || exit 1
          systemctl poweroff
          ;;
        *)
          pu_toast -t "System Control" -d 2.0 "Unknown action: '$action'"
          exit 1
          ;;
      esac
    }

    main "$@"
