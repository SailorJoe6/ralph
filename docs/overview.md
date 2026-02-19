# Overview

Ralph is SailorJoe's implementation of Geoffry Huntly's "Ralph Wiggum Loop": a reusable design -> plan -> execute workflow for AI-assisted development. It loops continuously until interrupted or until planning docs indicate there is no remaining work.

Runtime mode requires a V2 project root: the current working directory must contain a local `.ralph/` folder.  Run `ralph init` in the root folder of any project to set up Ralph to help you with that project.  

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
- Note: our execute prompt instructs your AI Agent (Claude, Codex) to move the plannign docs there if it gets bloecked so you can step in and help. 
- With default path settings this is `.ralph/plans/blocked/`.

**Key Project Paths**
- Project-root marker: `<project_root>/.ralph/`
- Project-specific configuration: `<project_root>/.ralph/.env`
- Runtime prompt lookup: `<project_root>/.ralph/prompts/`
- Planning docs (default): `<project_root>/.ralph/plans/`
- Logs (default): `<project_root>/.ralph/logs/`

**Key Global Paths**
- User configuration `~/.ralph/.env`
- Documentation: `~/.local/share/ralph/docs/`

---

**Next:** [install.md](install.md) - Global install layout, install script behavior, and update flow.
