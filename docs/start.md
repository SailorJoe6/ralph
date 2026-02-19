# Ralph Runtime

`ralph` runs Ralph's design -> plan -> execute loop. It chooses a prompt based on planning docs (or freestyle), invokes Claude or Codex, and repeats until interrupted, or the agent becomes blocked, or the agent completes all the work defined in the spec and plan.

`ralph start` is an alias and prints a reminder that `ralph` alone is fine.

**Usage**
```
ralph [OPTIONS]
ralph start [OPTIONS]
```

**Options**
- `--codex` Use Codex instead of Claude.
- `-y, --yolo` Enable full permissions while staying interactive.
- `-u, --unattended` Run non-interactive execution with full permissions during execute and handoff.
- `-f, --freestyle` Run execute loop with the prepare prompt, skipping spec/plan checks.
- `--resume [guid]` Resume a previous session on the first pass only. `guid` is optional for both Codex and Claude.
- `--container <name>` Execute commands inside a dev container using the configured container runtime.
- `--workdir <path>` Set container working directory (defaults to `/<basename>` when `--container` is used).
- `--callback <script>` Run a script after each pass.
- `-h, --help` Show help.

**Validation Rules**
- Passing both `--freestyle` and `--unattended` is normalized to interactive freestyle with yolo permissions.
- `--callback` must be executable and resolvable by `command -v`.
- `--container` requires the configured container runtime to exist.

**Project Root Enforcement**
- `ralph start` must be called from a project root.
- The script checks for a `.ralph/` folder in the current working directory, and will prompt you to run `ralph init` if not found.
- If `ralph/` (legacy V1 folder) is present instead, runtime hard-fails with migration guidance (`ralph/start` for legacy flow, or `ralph upgrade` to switch current project to V2).
- If `.ralph/` is found only in an ancestor directory, runtime hard-fails and prints a helpful message.
- If no project root is found, runtime hard-fails with guidance on how to initialize a project.

**Non-Interactive Mode**
- Non-interactive behavior only applies to execute mode when `--unattended` is set, in other nodes, it is treated the same as `--yolo`.
- In non-interactive mode, Ralph captures output and errors to log files. See [logging.md](logging.md).

**Handoff Behavior**
- In execute mode, handoff runs only if both planning docs still exist.
- Freestyle mode does not run automatic handoff between passes.
- In unattended mode, handoff runs non-interactively and appends output to `OUTPUT_LOG`.

**Exit And Looping**
- Ralph loops indefinitely; interrupt with repeated `Ctrl+C` keystrokes.
- If the agent exits with a non-zero status, Ralph prints the error log and exits.

---

**Next:** [interrupts.md](interrupts.md) - Ctrl+C behavior in interactive and non-interactive modes.
