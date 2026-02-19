# ralph Runtime

`ralph` runs Ralph's design -> plan -> execute loop. It chooses a prompt based on planning docs (or freestyle), invokes Claude or Codex, and repeats until interrupted.

`ralph start` is an alias and prints a reminder that `ralph` alone is the default command.

**Usage**
```
ralph [OPTIONS]
ralph start [OPTIONS]
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
- Runtime prompt files are read from `<project_root>/.ralph/prompts/*.md`.
- Freestyle always uses `.ralph/prompts/prepare.md` and is treated as execute mode.
- If both planning docs exist, Ralph uses `.ralph/prompts/execute.md`.
- If only `SPECIFICATION.md` exists, Ralph uses `.ralph/prompts/plan.md`.
- If neither planning doc exists, Ralph uses `.ralph/prompts/design.md`.
- If no planning docs exist but blocked docs are present under `$(dirname "$SPECIFICATION")/blocked`, Ralph uses `.ralph/prompts/blocked.md`.
- If `EXECUTION_PLAN.md` exists without `SPECIFICATION.md`, Ralph exits with an error.

**Validation Rules**
- Passing both `--freestyle` and `--unattended` is normalized to interactive freestyle with yolo permissions.
- `--callback` must be executable and resolvable by `command -v`.
- `--container` requires the configured container runtime to exist.
- Runtime mode does not support `--project`.

**Project Root Enforcement**
- Runtime requires `./.ralph/` in the current working directory.
- If `./ralph/` (legacy V1 folder) is present instead, runtime hard-fails with migration guidance (`./ralph/start` for legacy flow, or `ralph upgrade`).
- If `.ralph/` is found only in an ancestor directory, runtime hard-fails and prints both the current directory and discovered project root.
- If no project root is found, runtime hard-fails with `ralph init` and `ralph init --project <path>` guidance.
- If only `~/.ralph/` exists, runtime explains that it is global user config and cannot be used as a project root.

**Non-Interactive Mode**
- Non-interactive behavior only applies to execute mode when `--unattended` is set.
- In non-interactive mode, Ralph captures output and errors to log files. See [logging.md](logging.md).

**Handoff Behavior**
- In execute mode, handoff runs only if both planning docs still exist.
- In freestyle mode, handoff always runs.
- In unattended mode, handoff runs non-interactively and appends output to `OUTPUT_LOG`.

**Exit And Looping**
- Ralph loops indefinitely; interrupt with `Ctrl+C`.
- If the agent exits with a non-zero status, Ralph prints the error log and exits.
