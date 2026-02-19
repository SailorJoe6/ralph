# ralph init

`ralph init` is a deterministic initializer for the V2 project layout. It does not launch Claude or Codex.

**Usage**
```
ralph init [OPTIONS]
```

**Options**
- `--project <path>` Initialize a target project path. Relative paths resolve from the current working directory. Missing directories are created.
- `--stealth` Add folders created by this init run to `<project_root>/.git/info/exclude`.
- `--codex` Set up `.codex/commands/` symlinks to `.ralph` prompt files.
- `--beads` Run `bd init` in the target project root and use `.example.beads.md` prompt templates when available.
- `--claude` Set up `.claude/commands/` symlinks to `.ralph` prompt files.
- `-y, --yolo` Accepted for compatibility; has no effect in deterministic init.
- `-h, --help` Show help.

**Default Target**
- Without `--project`, `ralph init` uses the current working directory as project root.

**Tasks Performed**
- Create V2 directories (idempotent):
  - `<project_root>/.ralph`
  - `<project_root>/.ralph/prompts`
  - `<project_root>/.ralph/plans`
  - `<project_root>/.ralph/logs`
- Copy the bundled runtime `.env.example` to `<project_root>/.ralph/.env.example` (always overwrite destination).
- Create active prompt files in `<project_root>/.ralph/prompts/` from bundled templates, skipping pre-existing active prompt files.
- Generated prompt templates reference V2 planning paths under `.ralph/plans/...`.
- With `--beads`, run `bd init` when `.beads/` does not already exist and select `.example.beads.md` variants when they exist (`execute`, `handoff`, `prepare`), falling back to `.example.md` otherwise.
- With `--claude` and/or `--codex`, create command symlinks pointing to `.ralph` prompt files.

**Stealth Mode Details**
- Eligible folders: `.ralph`, `.beads`, `.codex`, `.claude`.
- Only folders created by this init run are added to `.git/info/exclude`.
- If git metadata is unavailable (for example target path is not in a git work tree), init prints a warning and continues.

**Runtime Requirements**
- `bd` must be available on `PATH` when `--beads` is used.
