# Overview

Ralph is SailorJoe's implementation of Geoffry Huntly's "Ralph Wiggum Loop": a reusable design -> plan -> execute workflow for AI-assisted development. It loops continuously until interrupted or until planning docs indicate there is no remaining work.

Runtime mode requires a V2 project root: the current working directory must contain `./.ralph/`.

**Phases**
- Design: if no planning docs exist, Ralph runs the design prompt and expects the agent to produce `SPECIFICATION.md`.
- Plan: if `SPECIFICATION.md` exists but `EXECUTION_PLAN.md` does not, Ralph runs the plan prompt and expects the agent to produce `EXECUTION_PLAN.md`.
- Execute: if both planning docs exist, Ralph runs the execute prompt and then handoff.
- Handoff: after each execute pass, Ralph runs the handoff prompt to capture context for the next session.

**Planning Docs And Phase Selection**
- Both `SPECIFICATION.md` and `EXECUTION_PLAN.md` present: execute phase.
- Only `SPECIFICATION.md` present: plan phase.
- Neither present: design phase.
- `EXECUTION_PLAN.md` without `SPECIFICATION.md`: error and exit.

**Freestyle Mode**
- `ralph --freestyle` skips planning-doc checks and runs the prepare prompt in interactive mode.
- Freestyle is always interactive. If `--unattended` is passed with `--freestyle`, Ralph treats it as `--yolo` (elevated permissions, still interactive). See [permissions.md](permissions.md).

**Blocked Mode**
- If no planning docs exist but blocked planning docs are present under `$(dirname "$SPECIFICATION")/blocked`, Ralph runs the blocked prompt.
- With default path settings this is `.ralph/plans/blocked/`.

**Key Paths**
- Project-root marker: `<project_root>/.ralph/`
- Runtime prompt lookup: `<project_root>/.ralph/prompts/`
- Planning docs (default): `.ralph/plans/`
- Logs (default): `.ralph/logs/`
- Documentation: `ralph/docs/`
