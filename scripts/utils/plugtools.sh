#!/usr/bin/env bash
[[ -n "$_ALPHA_PLUGTOOLS_SH" ]] && return 0
_ALPHA_PLUGTOOLS_SH=1

SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
PLUGINS_D="$PLUGIN_ROOT/plugins"
A_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/alpha-tmux"
UTILS="$PLUGIN_ROOT/scripts/utils"
CONFIG="$PLUGIN_ROOT/config"

CATALOG="$CONFIG/catalog.yaml"

source "$UTILS/yqtools.sh"
source "$UTILS/stepper.sh"

get_opt() {
  local plug="$1" prop="$2" fallback="$3" val
  local pfile="$PLUGINS_D/$plug/plugin.yaml"
  [[ -f "$pfile" ]] || { printf "%s\n" "$fallback"; return 1; }

  val="$(yq_get ".${prop}" "$pfile")"
  [[ "$val" == "null" ]] && val=""
  printf "%s\n" "${val:-$fallback}"
}

set_opt() {
  local plug="$1" prop="$2" val="$3"
  local pfile="$PLUGINS_D/$plug/plugin.yaml"
  [[ -f "$pfile" ]] || return 1

  yq_set ".${prop}" "$val" "$pfile"
}

step_opt() {
  local plug="$1" prop="$2" cur nxt
  cur="$(get_opt "$plug" "$prop")"
  shift 2
  nxt="$(stepper "$cur" "$@")"
  set_opt "$plug" "$prop" "$nxt"
}

unit() {
  local target="$1" depth="${2:-1}"
  local plugd plug enabled punit only_main start draw
  for plugd in "$PLUGINS_D"/*; do 
    [[ -f "$plugd/plugin.yaml" ]] || continue
    plug="$( basename "$plugd" )"
    
    enabled="$( get_opt "$plug" "enabled" "ON" )"
    [[ "$enabled" =~ ^(ON|1|true)$ ]] || continue
    
    punit="$( get_opt "$plug" "unit" "none" )"
    [[ "$punit" == "$target" ]] || continue

    only_main="$( get_opt "$plug" "only_main" "1" )" 
    if [[ "$only_main" =~ ^(ON|1|true)$ ]] && (( depth >1 )); then
      continue
    fi

    start="$( get_opt "$plug" "start" "init.sh" )" ## i would like start instead of start
    draw="$( get_opt "$plug" "draw" "${plug}_draw" )" ## also "draw" > "draw"

    if [[ -f "$plugd/$start" ]]; then
      source "$plugd/$start";
      declare -F "$draw" >/dev/null && "$draw"
    fi
  done
}

# synchronize 
sync() {
  local to_install=() to_update=() to_remove=()
  local repo plug plugd
  for repo in $( yq_each ".installed[].repo" "$CATALOG" ); do
    plug="${repo##*/}"
    if [[ -d "$PLUGINS_D/$plug" ]]; then
      to_update+=("$plug")
    else
      to_install+=("$repo")
    fi
  done
  for plugd in "$PLUGINS_D"/*; do
    [[ -d "$plugd" ]] || continue
    plug="${plugd##*/}"
    if [[ -z "$(yq_find ".installed" "name" "$plug" "name" "$CATALOG")" ]]; then
      to_remove+=("$plug")
    fi
  done
  (( "${#to_install[@]}" > 0 )) && install "${to_install[@]}"
  (( "${#to_update[@]}" > 0 )) && update "${to_update[@]}"
  (( "${#to_remove[@]}" > 0 )) && remove "${to_remove[@]}"
}

remove() {
  local plug
  for plug in "$@"; do
    [[ -n "$plug" ]] || continue
    rm -rf "${PLUGINS_D:?}/$plug"
    rm -rf "$A_CACHE/${plug}_"*
    yq_delete ".installed" "name" "$plug" "$CATALOG"
  done
}

clear_cache() {
  local mtime_arg=() days="${1:-}" cnt=0
  [[ -d "$A_CACHE" ]] || { echo 0; return 0; }
  [[ -n "$days" ]] && mtime_arg=(-mtime "+$days")
  while read -r item; do
    (( cnt++ ))
    rm -f "$item"
  done < <( find "$A_CACHE" -maxdepth 1 -type f ! -name 'highlights.yaml' ! -name 'state_*.yaml' "${mtime_arg[@]}" )
  printf "%d\n" "$cnt"
}

update() {
  local plug plugd
  for plug in "$@"; do 
    plugd="${PLUGINS_D}/$plug"
    [[ -d "$plugd/.git" ]] || continue
    if type -P "pv" &>/dev/null; then
      git -C "$plugd" pull --ff-only --progress 2>&1 | pv -t -N "$plug" >/dev/null
    else
      git -C "$plugd" pull --ff-only
    fi
  done
}

install() {
  local repo plug plugd url title ico desc
  for repo in "$@"; do
    plug="${repo##*/}"
    plugd="${PLUGINS_D}/$plug"
    url="https://github.com/${repo}.git"
    if type -P "pv" &>/dev/null; then
      git clone --progress "$url" "$plugd" 2>&1 | pv -t -N "$plug" >/dev/null
    else 
      git clone -q "$url" "$plugd"
    fi
    [[ -f "$plugd/plugin.yaml" ]] || continue
    title="$(get_opt "$plug" "title" "$plug")"
    ico="$(get_opt "$plug" "icon" "plug")"
    desc="$(get_opt "$plug" "desc" "")"
    yq_delete ".installed" "name" "$plug" "$CATALOG"
    yq_add ".installed" "$CATALOG" "name=$plug" "title=$title" "icon=$ico" "repo=$repo" "desc=$desc" 
  done
}

scaffold_plugin() {
  local plug="$1"
  [[ -n "$plug" ]] || return 1

  local plugd="$PLUGINS_D/$plug"
  local tmpl_d="$PLUGIN_ROOT/config/templates/plugin"
  [[ -d "$plugd" ]] && return 1
  [[ -d "$tmpl_d" ]] || return 1

  local fn_prefix="${plug//-/_}"
  local draw="${fn_prefix}_draw"
  local guard="_ALPHA_${fn_prefix^^}_SH"
  local title="${plug//-/ }"
  title="${title^}"

  mkdir -p "$plugd"
  sed -e "s|{{NAME}}|$plug|g" \
      -e "s|{{TITLE}}|$title|g" \
      -e "s|{{DRAW}}|$draw|g" \
      "$tmpl_d/plugin.yaml.tmpl" > "$plugd/plugin.yaml"

  sed -e "s|{{GUARD}}|$guard|g" \
      -e "s|{{TITLE}}|$title|g" \
      -e "s|{{DRAW}}|$draw|g" \
      "$tmpl_d/init.sh.tmpl" > "$plugd/init.sh"
  chmod +x "$plugd/init.sh"

  yq_delete ".installed" "name" "$plug" "$CATALOG"
  yq_add ".installed" "$CATALOG" "name=$plug" "title=$title" "icon=plug" "repo=local/$plug" "desc=Local plugin"
}

packer() {
  local plug="$1" out_d="${2:-$PWD}"
  out_d="${out_d/#\~/$HOME}"
  [[ -n "$plug" && -f "$PLUGINS_D/$plug/plugin.yaml" ]] || return 1
  mkdir -p "$out_d"
  local archive="${out_d%/}/${plug}.tar.gz"
  tar -czf "$archive" -C "$PLUGINS_D" "$plug" || return 1
  printf "%s\n" "$archive"
}

install_file() {
  local src="${1/#\~/$HOME}"
  [[ -n "$src" ]] || return 1

  local stage="" tmp_d="" yaml=""
  if [[ -d "$src" ]]; then
    [[ -f "$src/plugin.yaml" ]] || return 1
    stage="$src"
  elif [[ -f "$src" ]]; then
    tmp_d="$(mktemp -d)"
    case "$src" in
      *.tar.gz|*.tgz|*.tar.xz|*.tar.bz2|*.tar)
        tar -xf "$src" -C "$tmp_d" 2>/dev/null || { rm -rf "$tmp_d"; return 1; } ;;
      *.zip)
        unzip -q "$src" -d "$tmp_d" 2>/dev/null || { rm -rf "$tmp_d"; return 1; } ;;
      *)
        rm -rf "$tmp_d"; return 1 ;;
    esac
    yaml="$(find "$tmp_d" -maxdepth 2 -name "plugin.yaml" -print -quit)"
    [[ -n "$yaml" ]] || { rm -rf "$tmp_d"; return 1; }
    stage="$(dirname "$yaml")"
  else
    return 1
  fi

  local plug title ico desc start
  plug="$(yq_get ".name" "$stage/plugin.yaml")"
  [[ -z "$plug" || "$plug" == "null" ]] && plug="$(basename "$stage")"

  if [[ -d "$PLUGINS_D/$plug" ]]; then
    [[ -n "$tmp_d" ]] && rm -rf "$tmp_d"
    return 2
  fi

  cp -r "$stage" "$PLUGINS_D/$plug"
  [[ -n "$tmp_d" ]] && rm -rf "$tmp_d"

  start="$(get_opt "$plug" "start" "init.sh")"
  [[ -f "$PLUGINS_D/$plug/$start" ]] && chmod +x "$PLUGINS_D/$plug/$start"

  title="$(get_opt "$plug" "title" "$plug")"
  ico="$(get_opt "$plug" "icon" "plug")"
  desc="$(get_opt "$plug" "desc" "")"
  yq_delete ".installed" "name" "$plug" "$CATALOG"
  yq_add ".installed" "$CATALOG" "name=$plug" "title=$title" "icon=$ico" "repo=local/$plug" "desc=$desc"
  printf "%s\n" "$plug"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  "$@"
fi
