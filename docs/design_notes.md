# Alpha-Tmux Design Notes

## Blueprint File Format Compatibility
- Save files stored in $BLUEPRINTS_D (~/.config/alpha-tmux/blueprints/*.yaml) maintain 100% schema compatibility with Blueprint-format tmux session managers.
- Schema:
  - name: string (session display name)
  - created: string (timestamp)
  - root: string (working directory path)
  - windows: list
    - name: string (window name)
    - layout: string (tmux JSON-formatted layout string)
    - panes: list
      - path: string (pane working directory)
      - command: string (active command, or blank if standard interactive shell)

## User Interface Conventions
- User-facing menu items, toasts, and input prompts use natural "Session" terminology (e.g., "Load Session", "Save Session", "Save Session as...", "Delete Session") to keep the UI clean, intuitive, and consistent.
- Internal functions, file paths, and documentation retain "Blueprint" to explicitly denote format compatibility.
- Prominently feature "100% Blueprint Save File Compatibility" in README and project docs.
