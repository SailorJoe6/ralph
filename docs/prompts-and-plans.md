# Prompts And Planning Docs

Ralph's prompt files are hardcoded under `ralph/prompts/` and must be customized per project. Planning docs live under `ralph/plans/` by default.

**Required Prompt Files**
- `ralph/prompts/design.md`
- `ralph/prompts/plan.md`
- `ralph/prompts/execute.md`
- `ralph/prompts/handoff.md`
- `ralph/prompts/prepare.md`
- `ralph/prompts/blocked.md`

**Templates**
- Non-beads example templates live at `ralph/prompts/*.example.md`.
- Beads-specific example templates live at `ralph/prompts/*.example.beads.md` when available.
- `ralph/init` copies these into place, skipping files that already exist.

**Missing Prompt Behavior**
- If the selected prompt file is missing, `ralph/start` exits with an error and prints the exact `cp` commands to create missing prompts.
- The blocked prompt has no beads-specific variant; `ralph/init` copies `blocked.example.md` in both modes.

**Planning Docs**
- `SPECIFICATION.md` and `EXECUTION_PLAN.md` drive the design, plan, and execute phases.
- Defaults: `ralph/plans/SPECIFICATION.md`, `ralph/plans/EXECUTION_PLAN.md`.
- Paths can be overridden via environment variables. See `docs/configuration.md`.

**Blocked Plans**
- If neither planning doc exists but `ralph/plans/blocked/SPECIFICATION.md` or `ralph/plans/blocked/EXECUTION_PLAN.md` exists, Ralph uses `ralph/prompts/blocked.md`.
- This is intended for capturing blockers and unblocking steps when execution is paused.
