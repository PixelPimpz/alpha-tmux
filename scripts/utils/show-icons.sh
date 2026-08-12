#!/usr/bin/env bash
#
# Helper: List configured Nerd Font icons and names from lib/icons.yaml
#
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
PLUGIN_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"
ICONS_FILE="$PLUGIN_ROOT/lib/icons.yaml"

if [[ ! -f "$ICONS_FILE" ]]; then
  echo "Error: Could not find icons.yaml at $ICONS_FILE" >&2
  exit 1
fi

while IFS="|" read -r name glyph; do
  case "${#glyph}" in
    "4") icon="$(echo -e "\u$glyph")" ;;
    "5") icon="$(echo -e "\U$glyph")" ;;
    *)   icon="?" ;;
  esac
  printf "%-15s %s\n" "$name:" "$icon"
done < <(yq '.icons[] | [.name, .glyph] | join("|")' "$ICONS_FILE")
