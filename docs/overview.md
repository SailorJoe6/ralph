# Overview

Ralph is a reusable design → plan → execute workflow for AI-assisted development. It uses planning documents to decide which phase to run, and loops continuously until interrupted.

**Phases**
- Design: If no planning docs exist, Ralph runs the design prompt and expects the agent to produce `SPECIFICATION.md`.
- Plan: If `SPECIFICATION.md` exists but `EXECUTION_PLAN.md` does not, Ralph runs the plan prompt.
- Execute: If both planning docs exist, Ralph runs the execute prompt and then (optionally) handoff.
- Handoff: After each execute pass, Ralph can run the handoff prompt to update planning docs with context for the next session.

**Planning Docs And Phase Selection**
- Both `SPECIFICATION.md` and `EXECUTION_PLAN.md` present: execute phase.
- Only `SPECIFICATION.md` present: plan phase.
- Neither present: design phase.
- `EXECUTION_PLAN.md` without `SPECIFICATION.md`: error and exit.

**Freestyle Mode**
- `ralph/start --freestyle` skips planning doc checks and runs the prepare prompt in execute mode.
- Freestyle requires interactive input and cannot be combined with `--unattended`.

**Blocked Mode**
- If no planning docs exist but `ralph/plans/blocked/SPECIFICATION.md` or `ralph/plans/blocked/EXECUTION_PLAN.md` exist, Ralph runs the blocked prompt.
- This is intended for documenting blockers and guiding the next steps to unblock work.

**Key Paths**
- Prompts: `ralph/prompts/`
- Planning docs: `ralph/plans/`
- Logs: `ralph/logs/`
- Documentation: `ralph/docs/`
