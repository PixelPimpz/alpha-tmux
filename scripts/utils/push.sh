#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

# 1. Verify Git Repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  say "\n${ACCENTC}Error:${RESET} '$PWD' is not a git-managed directory.\n"
  pause "Press any key to return to main menu... "
  exit 1
fi

repo="$(basename "$PWD")"
branch="$(git branch --show-current 2>/dev/null || echo "HEAD")"
changes="$(git status --short)"

# 2. UI Dialog Contents
say "\n${TAGLINEC}Repo:${RESET} $repo (${KEYC}$branch${RESET})\n"

if [[ -n "$changes" ]]; then
  say "${TAGLINEC}Changes:${RESET}"
  echo "$changes" | sed 's/^/    /'
  echo ""
else
  say "${TAGLINEC}Clean working tree. There is nothing to do.${RESET}\n"
  pause
  exit 0
fi

# 3. Confirm Push
prompt "Push to ${repo}? [Y/n] " confirm
confirm="${confirm:-Y}"
if [[ "$confirm" =~ ^[nN]$ ]]; then
  say "\n${TAGLINEC}Cancelled.${RESET}\n"
  exit 0
fi

# 4. Commit Message (if uncommitted changes exist)
if [[ -n "$changes" ]]; then
  say "\nCommit message or [Enter] for default:"
  prompt "Message: " usr_msg
  commit_msg="${usr_msg:-Routine push: $(date "+%Y-%m-%d %H:%M:%S")}"
  git add .
  git commit -m "$commit_msg"
fi

# 5. Push and Feedback
say "\n${TAGLINEC}Pushing to origin/${branch}...${RESET}"
if git push origin "$branch"; then
  say "\n${TAGLINEC}✔ Push to remote successful!${RESET}\n"
else
  error "Push to remote failed"
fi

pause
exit 0
