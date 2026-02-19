# Prompts And Planning Docs

Ralph prompt selection is runtime-driven and planning-doc driven.

**Runtime Prompt Lookup**
- `ralph/start` reads active prompt files from `<project_root>/.ralph/prompts/`.
- Required prompt files:
- `.ralph/prompts/design.md`
- `.ralph/prompts/plan.md`
- `.ralph/prompts/execute.md`
- `.ralph/prompts/handoff.md`
- `.ralph/prompts/prepare.md`
- `.ralph/prompts/blocked.md`

**Prompt Templates**
- Non-beads template files live in `ralph/prompts/*.example.md`.
- Beads variants live in `ralph/prompts/*.example.beads.md` where available.
- `ralph init` copies templates into `<project_root>/.ralph/prompts/`, skipping existing destination files.
- Template content references V2 planning paths under `.ralph/plans/...`.
- If a selected runtime prompt is missing, `ralph` exits and prints prompt-creation guidance.

**Planning Docs**
- `SPECIFICATION.md` and `EXECUTION_PLAN.md` determine design/plan/execute phase selection.
- Default settings are `.ralph/plans/SPECIFICATION.md` and `.ralph/plans/EXECUTION_PLAN.md`.
- These are configurable via environment variables; see [configuration.md](configuration.md).

**Blocked Plans**
- Blocked-doc detection uses `$(dirname "$SPECIFICATION")/blocked`.
- With default settings, blocked docs are expected under `.ralph/plans/blocked/`.
- If blocked docs are present and primary planning docs are absent, Ralph selects `.ralph/prompts/blocked.md` and stays interactive.
