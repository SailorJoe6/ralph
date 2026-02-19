# ralph upgrade

`ralph upgrade` is the migration command for converting a legacy V1 `./ralph/` project layout into the V2 `./.ralph/` layout.

**Usage**
```
ralph upgrade [OPTIONS]
```

**Options**
- `--project <path>` Target project root to upgrade (defaults to current directory).
- `--stealth` Add created folders to `.git/info/exclude` when available.
- `-h, --help` Show help.

**Preconditions**
- `<project_root>/ralph/` must exist (legacy layout required).
- `<project_root>/.ralph/` must not already exist.
- If either check fails, upgrade exits with an error and makes no changes.

**Migration Behavior**
- Creates:
  - `<project_root>/.ralph/`
  - `<project_root>/.ralph/prompts/`
  - `<project_root>/.ralph/plans/`
  - `<project_root>/.ralph/logs/`
- Writes `<project_root>/.ralph/.env`:
  - Copies legacy `<project_root>/ralph/.env` when present.
  - Rewrites path variables that point into legacy `ralph/` to V2 defaults under `.ralph/`.
  - Emits a warning for each rewritten path key.
- Copies the bundled runtime `.env.example` to `<project_root>/.ralph/.env.example` (overwrite destination).
- Migrates known Ralph-managed artifacts (prompts, plans, logs, blocked plans) based on resolved migrated paths.

**Safety Constraints**
- Unknown files under legacy `<project_root>/ralph/` are preserved.
- Legacy `ralph/` is deleted only when no residual unknown content remains.
- `.beads`, `.codex`, and `.claude` are not migrated by `ralph upgrade`.

**Stealth Mode**
- With `--stealth`, only folders created by this run are appended to `.git/info/exclude`.
- For `ralph upgrade`, that is typically `.ralph/`.
- If git metadata is unavailable, upgrade continues and prints a warning.
