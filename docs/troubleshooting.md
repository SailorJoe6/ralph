# Troubleshooting

Common errors and fixes.

**Invalid Flag Combinations**
- `--freestyle` with `--unattended` is not valid, but supported for convenience. Passing these two flags is equivilent to passing `--freestyle --yolo`.
- `--resume <id>` without `--codex` is not allowed. Use `--resume` without an ID for Claude or add `--codex`.

**Missing Prompts**
- If a prompt file is missing, `ralph/start` prints the exact `cp` commands to create it.
- Ensure `ralph/prompts/blocked.md` exists if you use blocked mode.

**Container Errors**
- `Error: container not found` or `not running`: start the container and retry.
- `Error: <runtime> not found`: install or set `CONTAINER_RUNTIME` to a valid runtime.
- `Error: interactive mode requires a TTY`: run from a real terminal or use `--unattended`.

**Missing Agent CLI**
- `codex not found`: install Codex CLI or remove `--codex`.
- `claude not found`: install Claude CLI.

**Planning Docs Mismatch**
- `EXECUTION_PLAN.md` present without `SPECIFICATION.md` causes an error. Restore the spec or remove the plan.

**Exiting Ralph**
- Press CTRL+C repeatedly in rapid succession to exit Ralph completely. 
- If that doesn't work, you can try CTRL+\ or exit the terminal session. 
