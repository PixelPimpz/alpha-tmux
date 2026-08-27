#!/usr/bin/env bash
[[ -n "$_ALPHA_PUSH_SH" ]] && return 0
_ALPHA_PUSH_SH=1
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"
M="  "

source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf "\n%s" "${M}" 
  error "${PWD} not a git-managed directory."
  read -rp "${M}Press any key to return to aTmux Main Menu. " -n1
  exit 1
fi

repo="$( basename "$PWD" )"
branch="$( git branch --show-current 2>/dev/null || echo HEAD )"
changes="${M}$( git status --short )"

## UI Dialog contents
printf "\n"
printf "%s%bRepo:%b %s (%b%s%b)\n\n" "$M" "$TAGLINEC" "$RESET" "$repo" "$KEYC" "$branch" "$RESET"
if [[ -n "$changes" ]];then
  printf "%s%bChanges:%b\n%s\n\n" "${M}" "$TAGLINEC" "$RESET" "$changes"
else
printf "%s%bClean Working tree. There is nothing to do.%b\n\n" "${M}" "$TAGLINEC" "$RESET"
  read -rp "Press any key to return to main menu... " -n1 
  exit 0
fi

# confirm push
read -rp "${M}Push to ${repo}? [Y|n] " -n1 confirm
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
exit -14
