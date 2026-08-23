#!/usr/bin/env bash
SCRIPT_PATH="$( readlink -f "${BASH_SOURCE[0]}" )"
PLUGIN_ROOT="$( cd "$( dirname "$SCRIPT_PATH" )" && pwd )"

source "$PLUGIN_ROOT/scripts/utils/Stack.sh"

echo "=== Running Stack.sh Test Suite ==="

declare -a test_stack=()

# 1. Test Push
echo "-> Pushing elements..."
Stack_push test_stack "Alpha-TMUX"
Stack_push test_stack "Git Sync"
Stack_push test_stack "Submodules"

# 2. Test Size
Stack_size test_stack depth
echo "Stack depth (expected 3): $depth"

# 3. Test Peek
Stack_peek test_stack top
echo "Stack top (expected Submodules): $top"

# 4. Test Breadcrumbs (Join)
Stack_join test_stack breadcrumb
echo "Breadcrumb trail: $breadcrumb"

# 5. Test Pop (Back button)
echo "-> Popping top element..."
Stack_pop test_stack popped_item
echo "Popped item: $popped_item"

Stack_size test_stack depth
echo "New stack depth (expected 2): $depth"

Stack_join test_stack breadcrumb
echo "New trail after Back: $breadcrumb"

# 6. Test Clear
echo "-> Clearing stack..."
Stack_clear test_stack
Stack_size test_stack depth
echo "Stack depth after clear (expected 0): $depth"

echo "=== Tests Completed! ==="
