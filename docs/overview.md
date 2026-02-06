# Overview

Ralph is SailorJoe's implementation of Geoffry Huntly's "Ralph Wiggum Loop"... a reusable design → plan → execute workflow for AI-assisted development. It uses planning documents to decide which phase to run, and loops continuously until interrupted or until all work is done.

Ralph is fully automated and deterministically moves through it's workflow steps based on the presence/absence of it's design and planning docs.  

**Phases**
- Design: If no planning docs exist, Ralph runs the design prompt and expects the agent to produce `SPECIFICATION.md`.
- Plan: If `SPECIFICATION.md` exists but `EXECUTION_PLAN.md` does not, Ralph runs the plan prompt and expects the agent to produce `EXECUTION_PLAN.md`.
- Execute: If both planning docs exist, Ralph runs the execute prompt and then handoff.
- Handoff: After each execute pass, Ralph automatically runs the handoff prompt to update planning docs with context for the next session.

**Planning Docs And Phase Selection**
- Both `SPECIFICATION.md` and `EXECUTION_PLAN.md` present: execute phase.
- Only `SPECIFICATION.md` present: plan phase.
- Neither present: design phase.
- `EXECUTION_PLAN.md` without `SPECIFICATION.md`: error and exit.

**Freestyle Mode**
- `ralph/start --freestyle` skips planning doc checks and runs the prepare prompt in interactive mode.
- Freestyle is always interactive. If `--unattended` is passed with `--freestyle`, Ralph treats it as `--yolo` (elevated permissions, still interactive). See [permissions.md](permissions.md) for details on the difference.

**Blocked Mode**
- If no planning docs exist but `ralph/plans/blocked/SPECIFICATION.md` or `ralph/plans/blocked/EXECUTION_PLAN.md` exist, Ralph runs the blocked prompt.
- This is intended for documenting blockers and guiding the next steps to unblock work.

**Key Paths**
- Prompts: `ralph/prompts/`
- Planning docs: `ralph/plans/`
- Logs: `ralph/logs/`
- Documentation: `ralph/docs/`
