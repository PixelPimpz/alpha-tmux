#!/usr/bin/env bash
SCRIPT_SELF="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
SCRIPT_PATH="$SCRIPT_SELF"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/errors.sh"
source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/pop.sh"
source "$UTILS/icons.sh"
source "$UTILS/gitools.sh"

dirty=()
render_list() {
  printf "\n"
  local MARGIN file
  local go pass 

  go="$(get_icon "prog_up")"
  pass="$(get_icon "pass")"

  printf -v MARGIN "%*s" "${1:-8}" ""

  for file in "${dirty[@]}"; do
    if is_dirty "$PWD" >/dev/null; then
      printf "%s%s%s   %s %s%s%s\n" "${MARGIN}" "${ACCENTC}" "$go" "$RESET" "$TEXTC" "$file" "$RESET"
    else
      printf "%s%s%s   %s %s%s%s\n" "${MARGIN}" "${SUCCESSC}" "$pass" "$RESET" "$TEXTC" "$file" "$RESET"
    fi
  done
  printf "\n"
}

push_view() {
  trap 'cursor on' INT EXIT TERM
  local key msg repo branch
  repo="$(basename "$PWD")"
  branch="$(git branch --show-current 2>/dev/null || echo "HEAD")"

  # 1. Put each changed filename into dirty=() and find the longest one
  local line file longest=0
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    file="${line:3}"
    dirty+=("$file")
    (( ${#file} > longest )) && longest="${#file}"
    done < <(is_dirty "$PWD")

    # 2. Draw the file list (centered)
    local marginw
    marginw=$(get_margin $(( longest + 6 )))
    render_list "$marginw"

    # 3. Commit message first, confirmation second
    prompt "  ${PROMPTC}Commit message (optional): ${RESET}" msg
    echo ""
    cursor "off"
    read -rp "  ${PROMPTC}Push ${#dirty[@]} changed file(s) to ${repo} (${branch})? $(keys "Y" "$PROMPTC")/$(keys "n" "$PROMPTC"): ${RESET}" -n1 key
    echo ""
    [[ "$key" =~ ^[nN]$ ]] && exit 1

      # 4. Push, then redraw the list (now with green checkmarks!)
    push_repo "$PWD" "$msg"
    ac
    render_list "$marginw"

    say "  ${SUCCESSC}✔ ${repo} pushed!${RESET}\n"
    pause -b "Done. Press any key to return to main menu... "
    cursor "on"
}
 
main() {
  if [[ "$1" == "view" ]]; then
    push_view
    return
  fi

  if ! is_git "$PWD" &>/dev/null; then
    pu_toast -t "Sync Project" -d 2.0 "'$PWD' is not a git-managed directory."
    exit 1
  fi

  local changes repo branch
  changes="$(is_dirty "$PWD")"
  if [[ -z "$changes" ]]; then
    pu_toast -t "Sync Project" -d 2.0 "Clean working tree. Nothing to push."
    exit 1
  fi

  repo="$(basename "$PWD")"
  branch="$(git branch --show-current 2>/dev/null || echo "HEAD")"

  local sample_lines=("Sync Project: $repo" "")
  while IFS= read -r chg; do
    [[ -n "$chg" ]] && sample_lines+=("    ✔   ${chg:3}")
  done <<< "$changes"
  sample_lines+=("" "  Push changed file(s) to $repo ($branch)? [Y]/[n]" "Done. Press any key to return to main menu...")

  local w h
  read -r w h < <( popsizer "${sample_lines[@]}" )
  (( w < 54 )) && w=54
  (( h < 12 )) && h=12

  popped "" "Sync Project: $repo" "d" "$w" "$h" "$SCRIPT_SELF" view
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
