#!/usr/bin/env bash
SCRIPT_SELF="$( readlink -f "${BASH_SOURCE[0]:-$0}" )"
SCRIPT_PATH="$SCRIPT_SELF"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
UTILS="$PLUGIN_ROOT/scripts/utils"

source "$UTILS/errors.sh"
source "$UTILS/formats.sh"
source "$UTILS/colorizer.sh"
source "$UTILS/pop.sh"

check_git_repo() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo ""
    say "${ACCENTC}Error:${RESET} '$PWD' is not a git-managed directory.\n"
    pause
    return 1
  fi
  return 0
}

stage_and_commit() {
  local usr_msg commit_msg
  echo ""
  say "${HEADERC}Commit message or [Enter] for default:${RESET}"
  prompt "${PROMPTC}Message: ${RESET}" usr_msg
  commit_msg="${usr_msg:-Routine push: $(date "+%Y-%m-%d %H:%M:%S")}"
  git add .
  git commit -m "$commit_msg" >/dev/null 2>&1
}

do_push() {
  local branch="$1" push_output
  echo ""
  say "${PROMPTC}Pushing to origin/${branch}...${RESET}"
  if push_output="$(git push origin "$branch" 2>&1)"; then
    echo ""
    say "${SUCCESSC}✔ Push to remote successful!${RESET}\n"
  else
    echo ""
    say "${ACCENTC}✖ Push failed:${RESET}"
    echo "$push_output" | sed "s/^/    ${MUTEDC}/; s/$/${RESET}/"
    echo ""
  fi
}

push_view() {
  check_git_repo || exit 1

  local repo branch changes confirm
  repo="$(basename "$PWD")"
  branch="$(git branch --show-current 2>/dev/null || echo "HEAD")"
  changes="$(git status --short)"

  echo ""
  say "${HEADERC}Repo:${RESET} ${TEXTC}$repo${RESET} ${BRACKETC}(${KEYC}$branch${BRACKETC})${RESET}\n"

  if [[ -n "$changes" ]]; then
    say "${HEADERC}Changes:${RESET}"
    echo "$changes" | sed "s/^/    ${TEXTC}/; s/$/${RESET}/"
    echo ""
  else
    say "${TEXTC}Clean working tree. There is nothing to do.${RESET}\n"
    pause
    exit 0
  fi

  # Confirm push
  prompt "${PROMPTC}Push to ${TEXTC}${repo}${PROMPTC}? ${BRACKETC}[${KEYC}Y${BRACKETC}|${KEYC}n${BRACKETC}] ${RESET}" confirm
  confirm="${confirm:-Y}"
  if [[ "$confirm" =~ ^[nN]$ ]]; then
    echo ""
    say "${ACCENTC}Cancelled.${RESET}\n"
    exit 0
  fi

  stage_and_commit
  do_push "$branch"
  pause
}

main() {
  if [[ "$1" == "view" ]]; then
    push_view
    return
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    pu_toast -t "Sync Project" -d 2.0 "'$PWD' is not a git-managed directory."
    exit 1
  fi

  local changes repo branch
  changes="$(git status --short)"
  if [[ -z "$changes" ]]; then
    pu_toast -t "Sync Project" -d 2.0 "Clean working tree. Nothing to push."
    exit 0
  fi

  repo="$(basename "$PWD")"
  branch="$(git branch --show-current 2>/dev/null || echo "HEAD")"

  local sample_lines=()
  sample_lines+=("Repo: $repo ($branch)" "" "Changes:")
  while IFS= read -r chg; do
    [[ -n "$chg" ]] && sample_lines+=("    $chg")
  done <<< "$changes"
  sample_lines+=("" "Commit message or [Enter] for default:" "Push to $repo? [Y|n]" "✔ Push to remote successful!")

  local w h
  read -r w h < <( popsizer "${sample_lines[@]}" )
  (( w < 50 )) && w=50
  (( h < 12 )) && h=12

  popped "" "Sync Project" "d" "$w" "$h" "$SCRIPT_SELF" view
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
