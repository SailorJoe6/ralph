# ralph/start

`ralph/start` runs Ralph's design → plan → execute loop. It selects the prompt based on planning docs (or freestyle), invokes Claude or Codex, and repeats until interrupted.

**Usage**
```
ralph/start [OPTIONS]
```

**Options**
- `-u, --unattended` Run non-interactive execution with elevated permissions during execute and handoff.
- `-f, --freestyle` Run execute loop with the prepare prompt, skipping spec/plan checks.
- `-y, --yolo` Enable full permissions while staying interactive unless combined with `--unattended`.
- `--codex` Use Codex instead of Claude.
- `--resume [guid]` Resume a previous session on the first pass only. `guid` is optional for both Codex and Claude.
- `--container <name>` Execute commands inside a container using the configured runtime.
- `--workdir <path>` Set container working directory (defaults to `/<basename>` when `--container` is used).
- `--callback <script>` Run a script after each pass.
- `-h, --help` Show help.

**Prompt And Phase Selection**
- Freestyle mode always uses `ralph/prompts/prepare.md` and is treated as execute mode.
- If both planning docs exist, Ralph uses `ralph/prompts/execute.md`.
- If only `SPECIFICATION.md` exists, Ralph uses `ralph/prompts/plan.md`.
- If neither planning doc exists, Ralph uses `ralph/prompts/design.md`.
- If no planning docs exist but files are present in `ralph/plans/blocked/`, Ralph uses `ralph/prompts/blocked.md`.
- If `EXECUTION_PLAN.md` exists without `SPECIFICATION.md`, Ralph exits with an error.

**Validation Rules**
- `--freestyle` cannot be combined with `--unattended`.
- `--callback` must be executable and resolvable by `command -v`.
- `--container` requires the configured container runtime to exist.

**Non-Interactive Mode**
- Non-interactive behavior only applies to execute mode when `--unattended` is set.
- In non-interactive mode, Ralph captures output and errors to log files. See `docs/logging-and-callbacks.md`.

**Handoff Behavior**
- In execute mode, handoff runs only if both planning docs still exist.
- In freestyle mode, handoff always runs.
- In unattended mode, handoff runs non-interactively and logs output to `OUTPUT_LOG`.

**Exit And Looping**
- Ralph loops indefinitely; interrupt with Ctrl+C.
- If the agent exits with a non-zero status, Ralph prints the error log and exits.
