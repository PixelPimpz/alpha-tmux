#!/usr/bin/env bash
## nerds.sh
# Nerd Font icon lookup utility for alpha-tmux
[[ -n "$_ALPHA_NERDS_SH" ]] && return 0
_ALPHA_NERDS_SH=1

PLUGIN_ROOT="${PLUGIN_ROOT:-$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )/../.." && pwd )}"
source "$PLUGIN_ROOT/scripts/utils/yqtools.sh"

nf() {
  local CACHE_D="${XDG_CACHE_HOME:-$HOME/.cache}/nerd-fonts"
  local GLYPH_CACHE="$CACHE_D/glyphnames.json"
  local REMOTE="https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/glyphnames.json"

  # 1. Ensure cache directory & catalog exist
  if [[ ! -s "$GLYPH_CACHE" ]]; then
    mkdir -p "$CACHE_D"
    echo "Downloading Nerd Font glyph catalog..." >&2
    curl -fsSL "$REMOTE" -o "$GLYPH_CACHE" || { echo "Failed to download glyph catalog." >&2; return 1; }
  fi

  # 2. Parse flags
  local mode="all" clip=0 query=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -g|--glyph)   mode="glyph" ;;
      -n|--name)    mode="name" ;;
      -u|--unicode) mode="unicode" ;;
      -e|--escape)  mode="escape" ;;
      -c|--clip)    clip=1 ;;
      -gc|-cg)      mode="glyph"; clip=1 ;;
      -ec|-ce)      mode="escape"; clip=1 ;;
      -nc|-cn)      mode="name"; clip=1 ;;
      -uc|-cu)      mode="unicode"; clip=1 ;;
      -h|--help)
        echo "Usage: nf [-g|-n|-u|-e] [-c] <name|hex>"
        echo "  -g, --glyph    Output the glyph icon"
        echo "  -n, --name     Output the glyph name"
        echo "  -u, --unicode  Output the Unicode code point (U+XXXX)"
        echo "  -e, --escape   Output the Bash escape sequence (\\uXXXX)"
        echo "  -c, --clip     Copy result to clipboard"
        echo "  (no args)      Interactive fzf selector"
        return 0
        ;;
      -*) echo "Unknown option: $1" >&2; return 1 ;;
      *)  query="$1" ;;
    esac
    shift
  done

  local out

  # 3. Interactive fzf if no query provided
  if [[ -z "$query" ]]; then
    if command -v fzf &>/dev/null; then
      local selection
      selection="$(jq -r 'to_entries[] | "\(.value.char)\t\(.key)\tU+\(.value.code | ascii_upcase)\t\\u\(.value.code)"' "$GLYPH_CACHE" \
        | column -t -s $'\t' \
        | fzf --prompt="Nerd Font > " --reverse --height=40%)"
      [[ -z "$selection" ]] && return 0
      
      read -r _g _n _u _e <<< "$selection"
      case "$mode" in
        glyph)   out="$_g" ;;
        name)    out="$_n" ;;
        unicode) out="$_u" ;;
        escape)  out="$_e" ;;
        *)       out="$selection" ;;
      esac
    else
      echo "No search term provided and fzf is not installed." >&2
      return 1
    fi
  else
    # 4. Sanitize hex / name query
    local hex="${query#[Uu]+}"
    hex="${hex#0x}"
    hex="${hex#\\u}"
    hex="${hex,,}"
    [[ "$hex" =~ ^[0-9a-f]{4,6}$ ]] || hex=""

    # 5. Query via jq
    out="$(jq -r --arg q "$query" --arg hex "$hex" --arg mode "$mode" '
      to_entries
      | (
          map(select((.value.code == $hex) or (.key == $q))) as $exact
          | if ($exact | length) > 0 then $exact
            elif $q != "" then map(select(.key | ascii_downcase | contains($q | ascii_downcase)))
            else .
            end
        )[]
      | if $mode == "glyph" then .value.char
        elif $mode == "name" then .key
        elif $mode == "unicode" then "U+" + (.value.code | ascii_upcase)
        elif $mode == "escape" then "\\u" + .value.code
        else "\(.value.char)\t\(.key)\tU+\(.value.code | ascii_upcase)\t\\u\(.value.code)"
        end
    ' "$GLYPH_CACHE")"

    [[ -z "$out" ]] && { echo "No glyph found matching: $query" >&2; return 1; }

    if [[ "$mode" == "all" ]]; then
      out="$(printf "%s\n" "$out" | column -t -s $'\t')"
    fi
  fi

  # 6. Clipboard integration
  if [[ "$clip" -eq 1 ]]; then
    if command -v wl-copy &>/dev/null; then
      printf "%s" "$out" | wl-copy
    elif command -v xclip &>/dev/null; then
      printf "%s" "$out" | xclip -selection clipboard
    elif [[ -n "$TMUX" ]]; then
      printf "%s" "$out" | tmux load-buffer -
    fi
  fi

  printf "%s\n" "$out"
}

## Helper to add or update a glyph in config/icons.yaml
# Usage: add_glyph_yaml <name> <hex>
#    or: add_glyph_yaml <name_or_hex>  (auto-resolved via nf)
add_glyph_yaml() {
  local ICONS="${ICONS:-$PLUGIN_ROOT/config/icons.yaml}"
  local name="$1" hex="$2"

  if [[ $# -eq 1 ]]; then
    local arg="$1"
    local raw_hex="${arg#[Uu]+}"
    raw_hex="${raw_hex#0x}"
    raw_hex="${raw_hex#\\u}"
    raw_hex="${raw_hex,,}"

    if [[ "$raw_hex" =~ ^[0-9a-f]{4,6}$ ]]; then
      hex="$raw_hex"
      name="$(nf -n "$hex")"
    else
      name="$arg"
      local u
      u="$(nf -u "$name")"
      hex="${u#U+}"
      hex="${hex,,}"
    fi
  else
    local u
    u="$(nf -u "$hex")"
    if [[ -n "$u" ]]; then
      hex="${u#U+}"
      hex="${hex,,}"
    else
      local clean_h="${hex#[Uu]+}"
      clean_h="${clean_h#0x}"
      clean_h="${clean_h#\\u}"
      hex="${clean_h,,}"
    fi
  fi

  [[ -z "$name" || -z "$hex" ]] && { echo "Failed to resolve glyph for '$1'" >&2; return 1; }

  # Upsert: remove existing if present, then add
  rem_glyph_yaml "$name" 2>/dev/null
  yq_add ".icons" "$ICONS" name="$name" glyph="$hex"
}

## Helper to remove a glyph from config/icons.yaml by name
# Usage: rem_glyph_yaml <name>
rem_glyph_yaml() {
  local ICONS="${ICONS:-$PLUGIN_ROOT/config/icons.yaml}"
  local name="$1"
  [[ -z "$name" ]] && return 1
  yq_delete ".icons" "name" "$name" "$ICONS"
}
