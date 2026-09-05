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

# Query a property from a record in a YAML list matching key=value
# Usage: yq_find ".icons" "name" "folder" "glyph" "$ICONS"
# Usage: yq_find ".Profiles" "status" "active" "theme" "$CONF"
yq_find() {
  local list="$1" m_key="$2" m_val="$3" prop="$4" file="$5"
  [[ -f "$file" ]] || return 1
  yq eval "${list}[] | select(.${m_key} == \"${m_val}\") | .${prop}" "$file" 2>/dev/null
}

# Update a property of a record in a YAML list in-place
# Usage: yq_update ".Profiles" "status" "active" "theme" "nord" "$CONF"
yq_update() {
  local list="$1" m_key="$2" m_val="$3" prop="$4" val="$5" file="$6"
  [[ -f "$file" ]] || return 1
  yq eval -i "(${list}[] | select(.${m_key} == \"${m_val}\")).${prop} = \"${val}\"" "$file"
}

# Delete a record from a YAML list matching key=value in-place
# Usage: yq_delete ".icons" "name" "folder" "$ICONS"
yq_delete() {
  local list="$1" m_key="$2" m_val="$3" file="$4"
  [[ -f "$file" ]] || return 1
  yq eval -i "del(${list}[] | select(.${m_key} == \"${m_val}\"))" "$file"
}

# Append a new record to a YAML list in-place
# Usage: yq_add ".icons" "$ICONS" name="folder" glyph="f07b"
yq_add() {
  local list="$1" file="$2"
  shift 2
  [[ -f "$file" ]] || return 1

  local pair k v payload=""
  for pair in "$@"; do
    k="${pair%%=*}"
    v="${pair#*=}"
    [[ -n "$payload" ]] && payload+=", "
    payload+="\"$k\": \"$v\""
  done
  yq eval -i "${list} += [{${payload}}]" "$file"
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
  source "$PLUGIN_ROOT/scripts/utils/profiler.sh"
  get_active "theme"
}

get_icon() {
  source "$PLUGIN_ROOT/scripts/utils/icons.sh"
  get_icon "$@"
}
