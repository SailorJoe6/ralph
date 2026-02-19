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
- `--claude` Set up `.claude/commands/` symlinks to `.ralph` prompt files.
- `--beads` Run `bd init` in the target project root and use `.example.beads.md` prompt templates when available.
- `-h, --help` Show help.

**Default Target**
- Without `--project`, `ralph init` uses the current working directory as project root.

**Tasks Performed**
- Create V2 directories (idempotent):
  - `<project_root>/.ralph`
  - `<project_root>/.ralph/prompts`
  - `<project_root>/.ralph/plans`
  - `<project_root>/.ralph/logs`
- Create active prompt files in `<project_root>/.ralph/prompts/` from bundled templates, preserving any pre-existing active prompt files.
- Copy the bundled runtime `.env.example` to `<project_root>/.ralph/.env.example` (always overwrite with latest example file).
- With `--beads`, run `bd init` when `.beads/` does not already exist and select `.example.beads.md` variants when they exist (`execute`, `handoff`, `prepare`), falling back to `.example.md` otherwise.
- With `--claude` and/or `--codex`, create command symlinks pointing to `.ralph` prompt files.

Note: The default prompts reference planning paths under `.ralph/plans/...` so if you change this via [configuration](configuration.md), be sure to update the prompts!


**Stealth Mode Details**
Stealth mode ensures your local tooling info doesn't get tracked in git, by adding folders to `<project_root>/.git/info/exclude`.  
- Eligible folders: `.ralph`, `.beads`, `.codex`, `.claude`.
- Only folders created by this init run are added to `.git/info/exclude`.
- If git metadata is unavailable (for example target path is not in a git work tree), init prints a warning and continues.

**Runtime Requirements**
- `bd` must be available on `PATH` when `--beads` is used.

---

**Next:** [upgrade.md](upgrade.md) - `ralph upgrade` CLI reference (migration command).
