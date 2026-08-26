#!/usr/bin/env bash
[[ -n "$_ALPHA_PUSH_SH" ]] && return 0
_ALPHA_PUSH_SH=1
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  error "$PWD not a git-managed directory."
  read -rp "Press any key to return to aTmux Main Menu. " -n1
  exit 1
fi

repo="$( basename "$PWD" )"
branch="$( git branch --show-current 2>/dev/null || echo HEAD )"
changes="$( git status --short )"

## UI Dialog contents
printf "%bRepo:%b %s (%b%s%b)\n\n" "$TAGLINEC" "$RESET" "$repo" "$KEYC" "$branch" "$RESET"
if [[ -n "$changes" ]];then
  printf "%bChanges:%b\n%s\n\n" "$TAGLINEC" "$RESET" "$changes"
else
  printf "%bClean Working tree. There is nothing to do.%b\n\n"  "$TAGLINEC" "$RESET"
fi

# confirm push
read -rp "Push to ${repo}? [Y|n] " -n1 confirm
confirm="${confirm:-Y}"
if [[ "$confirm" =~ ^[nN]$ ]]; then
  printf "\n%bCancelled.%b\n" "$TAGLINEC" "$RESET"
  exit 0
fi

# push if there are changes
if [[ -n "$changes" ]]; then
  printf "\n"
  read -rp "Commit messages: [ Enter ] for routine message + timestamp " usr_msg
  commit_msg="${usr_msg:-Routine push: $(date  "+%Y-%m-%d %H:%M:%S")}"
  git add .
  git commit -m "$commit_msg" 
fi

# Push and Fedback
printf "\n%bPushing to origin/%s...%b\n" "$TAGLINEC" "$branch" "$RESET"
if git push origin "$branch"; then
  printf "\n%bPush to remote successful! %b\n\n" "$TAGLINEC" "$RESET"
else
  error "Push to remote failed"
fi

read -rp "Press any key to return to main menu. " -n1 
exit 0
