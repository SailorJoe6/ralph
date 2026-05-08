# ralph upgrade

`ralph upgrade` is the migration command for converting legacy Ralph project layouts into the current skills-first V2 `.ralph/` layout.

**Usage**
```
ralph upgrade [OPTIONS]
```

**Options**
- `--project <path>` Target project root to upgrade (defaults to current directory).
- `--stealth` Add created folders to `.git/info/exclude` when available.
- `-h, --help` Show help.

**Supported Inputs**
- V1 layout: `<project_root>/ralph/`
- Old V2 prompt layout: `<project_root>/.ralph/prompts/` when `<project_root>/.ralph/skills/` does not already exist

For V1 upgrades, `<project_root>/.ralph/` must not already exist. For old V2 upgrades, the existing `.ralph/` directory is migrated in place.

**Migration Behavior**
- Creates:
  - `<project_root>/.ralph/`
  - `<project_root>/.ralph/skills/<phase>/SKILL.md`
  - `<project_root>/.ralph/plans/`
  - `<project_root>/.ralph/logs/`
- Writes `<project_root>/.ralph/.env`:
  - Copies legacy `<project_root>/ralph/.env` when present.
  - Rewrites path variables that point into legacy `ralph/` to V2 defaults under `.ralph/`.
  - Emits a warning for each rewritten path key.
- Copies the bundled runtime `.env.example` to `<project_root>/.ralph/.env.example` when creating a new V2 layout.
- Migrates known Ralph-managed artifacts based on resolved migrated paths.
- Moves each active legacy prompt file into `<project_root>/.ralph/skills/<phase>/SKILL.md`, preserving custom prompt bodies exactly. Existing destination skill files with different content are preserved and reported.
- Removes `.ralph/prompts/` only when all known prompt files migrated and no unknown content remains.
- Migrates Ralph-managed `.claude/commands/<phase>.md` and `.codex/commands/<phase>.md` symlinks into `.claude/skills/<phase>` and `.codex/skills/<phase>` directory symlinks.
- Creates shared `.agents/skills/<phase>` directory symlinks when assistant-specific Ralph-managed command symlinks are migrated.
- Replaces old assistant skill directories that contained a Ralph-managed symlinked `SKILL.md` with directory symlinks to `.ralph/skills/<phase>`.

**Safety Constraints**
- Unknown files under legacy `<project_root>/ralph/` or old `.ralph/prompts/` are preserved.
- Custom command files, unrelated symlinks, and custom assistant skill directories are preserved.
- Legacy `ralph/` is deleted only when no residual unknown content remains, or when a clean nested legacy git repository proves the residual content is safe to remove.

**Stealth Mode**
- With `--stealth`, only folders created by this run are appended to `.git/info/exclude`.
- If git metadata is unavailable, upgrade continues and prints a warning.

---

**Next:** [start.md](start.md) - `ralph` runtime CLI reference, phase selection, and handoff behavior.
