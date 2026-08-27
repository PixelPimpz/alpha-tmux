#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )/../.." && pwd )"

source "$PLUGIN_ROOT/scripts/utils/errors.sh"
source "$PLUGIN_ROOT/scripts/utils/formats.sh"
source "$PLUGIN_ROOT/scripts/utils/colorizer.sh"

# 1. Verify Git Repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo ""
  say "${ACCENTC}Error:${RESET} '$PWD' is not a git-managed directory.\n"
  pause "Press any key to return to main menu... "
  exit 1
fi

repo="$(basename "$PWD")"
branch="$(git branch --show-current 2>/dev/null || echo "HEAD")"
changes="$(git status --short)"

# 2. UI Dialog Contents
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

# 3. Confirm Push
prompt "${PROMPTC}Push to ${TEXTC}${repo}${PROMPTC}? ${BRACKETC}[${KEYC}Y${BRACKETC}|${KEYC}n${BRACKETC}] ${RESET}" confirm
confirm="${confirm:-Y}"
if [[ "$confirm" =~ ^[nN]$ ]]; then
  echo ""
  say "${ACCENTC}Cancelled.${RESET}\n"
  exit 0
fi

# 4. Commit Message (if uncommitted changes exist)
if [[ -n "$changes" ]]; then
  echo ""
  say "${HEADERC}Commit message or [Enter] for default:${RESET}"
  prompt "${PROMPTC}Message: ${RESET}" usr_msg
  commit_msg="${usr_msg:-Routine push: $(date "+%Y-%m-%d %H:%M:%S")}"
  git add .
  git commit -m "$commit_msg" >/dev/null 2>&1
fi

# 5. Push and Feedback
echo ""
say "${PROMPTC}Pushing to origin/${branch}...${RESET}"
local push_output
if push_output="$(git push origin "$branch" 2>&1)"; then
  echo ""
  say "${SUCCESSC}✔ Push to remote successful!${RESET}\n"
else
  echo ""
  say "${ACCENTC}✖ Push failed:${RESET}"
  echo "$push_output" | sed "s/^/    ${MUTEDC}/; s/$/${RESET}/"
  echo ""
fi

pause
exit 0
