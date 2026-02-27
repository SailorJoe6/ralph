# Troubleshooting

Common errors and fixes.

**Flag Combinations**
- `--freestyle` with `--unattended` is accepted but normalized to `--freestyle --yolo`.
- `--resume [id]` is valid with either tool. If `id` is omitted, Ralph resumes the latest session on the first pass only.

**Missing Prompts**
- If a selected prompt file is missing, `ralph` exits and prints prompt-creation guidance.
- Runtime prompt lookup path is `<project_root>/.ralph/prompts/` in normal flow, and `<cwd>/.ralph/prompts/` in `--freestyle`.

**Container Errors**
- `Error: container not found` or `Error: container is not running`: start the container and retry.
- `Error: <runtime> not found`: install the runtime or set `CONTAINER_RUNTIME` to a valid executable.
- `Error: interactive mode requires a TTY`: run from a real terminal or use `--unattended`.

**Missing Agent CLI**
- `codex not found`: install Codex CLI or remove `--codex`.
- `claude not found`: install Claude CLI.

**Planning Docs Mismatch**
- `EXECUTION_PLAN.md` present without `SPECIFICATION.md` causes an error. Restore the spec or remove the plan.

**Runtime Root Errors**
- `Ralph runtime requires a V2 project root`: run from a directory that contains `.ralph/`, or initialize one with `ralph init` (this check is skipped in `--freestyle`).
- `legacy V1 Ralph folder detected`: current directory has `ralph/` (V1 layout). Use `ralph/start` for legacy behavior or run `ralph upgrade`.
- `Ralph must be run from the project root directory`: move to the detected root shown in the error and rerun.

**Exiting Ralph**
- Press `Ctrl+C` repeatedly in rapid succession to exit Ralph completely.
- If that does not work, try `Ctrl+\` or exit the terminal session.
