# Prompts And Planning Docs

The `ralph` script selects prompts to feed into Claude or Codex in order to control execution flow.

**Runtime Prompt Lookup**
`ralph` reads active prompt files from `<project_root>/.ralph/prompts/` by default. See [configuration.md](configuration.md).

Required prompt files:
- `.ralph/prompts/design.md`
- `.ralph/prompts/plan.md`
- `.ralph/prompts/execute.md`
- `.ralph/prompts/handoff.md`
- `.ralph/prompts/prepare.md`
- `.ralph/prompts/blocked.md`

**Prompt Templates**
- Non-beads template files live in `~/.local/share/ralph/prompts/*.example.md`.
- Beads variants live in `~/.local/share/ralph/prompts/*.example.beads.md` where available.
- `ralph init` copies templates into `<project_root>/.ralph/prompts/`, preserving any existing destination files.
- These default prompts reference V2 planning paths under `.ralph/plans/...`, so if you choose to customize their locations, update the prompts too!
- If a required runtime prompt is missing, `ralph` exits and prints prompt-creation guidance.

**Planning Docs**
- The runtime chooses which mode to enter on every iteration based on `SPECIFICATION.md` and `EXECUTION_PLAN.md`.
- When neither file exists, Ralph feeds `prepare.md` to Claude or Codex in interactive mode (default free-form entry).
- When only `SPECIFICATION.md` exists, Ralph feeds `plan.md` to Claude or Codex in interactive mode.
- When both files exist, Ralph feeds `execute.md` to Claude or Codex. Flags control whether this happens in interactive or unattended mode.
- `design.md` remains available for on-demand use (for example via slash commands) when you want to create or revise `SPECIFICATION.md`.

- By default, these plan files are expected at `.ralph/plans/SPECIFICATION.md` and `.ralph/plans/EXECUTION_PLAN.md`.
- This is all configurable via environment variables; see [configuration.md](configuration.md).

**Blocked Plans**
- Blocked-doc detection checks for the presence of the plan and spec under `.ralph/plans/blocked/` by default. 
- If blocked docs are present, Ralph feeds `.ralph/prompts/blocked.md` to the AI Agent in interactive mode.  

---

**Next:** [logging.md](logging.md) - Log files, unattended logging, and error capture.
