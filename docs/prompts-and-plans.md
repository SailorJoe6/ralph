# Prompts And Planning Docs

Ralph's prompt files are expected (hardcoded) to be found under `ralph/prompts/` and must be customized per project. Planning docs live under `ralph/plans/` by default but this can be customized in your (configuration)[ralph/docs/configuration.md].

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
- The blocked prompt has no beads-specific variant.  Once you're blocked, you're blocked and beads is irrelevant. So, `ralph/init` just copies `blocked.example.md` in both modes.

**Planning Docs**
- `SPECIFICATION.md` and `EXECUTION_PLAN.md` drive the design, plan, and execute phases.
- Defaults: `ralph/plans/SPECIFICATION.md`, `ralph/plans/EXECUTION_PLAN.md`.
- Paths can be overridden via environment variables. See (configuration)[ralph/docs/configuration.md].  This is useful when you want to keep your design and plan in the parent project's repo, since Ralph's .gitignore keeps these files out of Ralph's repo. 

**Blocked Plans**
- If the planning docs exist, but are located under `ralph/plans/blocked`, Ralph uses the `ralph/prompts/blocked.md` prompt and enters interactive mode.  
- This is intended for capturing blockers and unblocking steps when execution is paused.
- This allows you the chance to unblock Ralph.  If you succesfully unblock the project, just exit the current Claude/Codex session and ralph will automatically re-enter the execution phase on the next loop iteration.  
