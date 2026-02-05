# ralph/init

`ralph/init` runs an AI agent to initialize Ralph in a project. It can set up beads, copy prompt templates, and create slash-command symlinks.

**Usage**
```
ralph/init [OPTIONS]
```

**Options**
- `--codex` Use Codex instead of Claude and set up `.codex/commands/` symlinks.
- `--beads` Initialize beads with `bd init` and use `.example.beads.md` prompt templates.
- `--claude` Set up `.claude/commands/` symlinks.
- `-y, --yolo` Run the agent with full permissions.
- `-h, --help` Show help.

**Tasks Performed**
- Add `ralph/` to `.git/info/exclude` in the parent repo, if it is a git repository.
- Copy prompt templates into `ralph/prompts/`, skipping any files that already exist.
- If `--beads` is set, use `.example.beads.md` templates when available.
- If `--claude` is set, create symlinks under `.claude/commands/` to each prompt file.
- If `--codex` is set, create symlinks under `.codex/commands/` to each prompt file.

**Runtime Requirements**
- When using `--codex`, `codex` must be available on PATH.
- Otherwise, `claude` must be available on PATH.
