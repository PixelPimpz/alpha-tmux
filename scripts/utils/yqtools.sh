#!/usr/bin/env bash
[[ -n "$_ALPHA_YQTOOLS_SH" ]] && return 0
_ALPHA_YQTOOLS_SH=1

source "$PLUGIN_ROOT/scripts/utils/errors.sh"

## -----------------------------------------------------------------
# Pure, domain-agnostic YAML helpers using yq
## -----------------------------------------------------------------

# Read a key path or evaluate an expression
# Usage: yq_get ".ui.header" "$THEME_FILE"
yq_get() {
  local expr="$1" file="$2"
  [[ -f "$file" ]] || return 1
  yq eval "$expr" "$file"
}

# Write a value to a YAML file in-place
# Usage: yq_set ".Profiles[0].theme" "nord" "$CONFIG_FILE"
yq_set() {
  local expr="$1" val="$2" file="$3"
  [[ -f "$file" ]] || return 1
  yq eval -i "${expr} = \"${val}\"" "$file"
}

yqshow() {
  local file="${1:-$2}"
  [[ ! -n "$file" || ! -f "$file" ]] && fatal "$file not found."
  yq e . "$file"
}

is_yaml() {
  [[ "$1" == *.yaml || "$1" == *.yml ]]
}

# Backwards compatibility delegates
get_active_theme() {
  source "$PLUGIN_ROOT/scripts/utils/settings.sh"
  get_active "theme"
}

get_icon() {
  source "$PLUGIN_ROOT/scripts/utils/icons.sh"
  get_icon "$@"
}
