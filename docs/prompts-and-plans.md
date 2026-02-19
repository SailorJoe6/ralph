# Prompts And Planning Docs

The ralph script selects prompts to feed into claude or codex in order to control the exection flow.  

**Runtime Prompt Lookup**
`ralph` reads active prompt files from `<project_root>/.ralph/prompts/` by default. see [configuration.md](configuration.md).

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
- The ralph scriot chooses which mode to enter on every iteration in accordance with the location of `SPECIFICATION.md` and `EXECUTION_PLAN.md`.
    - when neither file exists, Ralph feeds the design.md prompt to Claude or Codex in interactive mode. 
    - when only `SPECIFICATION.md` exists, Ralph feeds the plan.md prompt to Claude or Codex in interactive mode.
    - when both files exist, Ralph feeds the execute.md prompt to Claude or Codex.  Flags control whehter this happens in interactive or unnattended mode.

- By default, these plan files are expected at `.ralph/plans/SPECIFICATION.md` and `.ralph/plans/EXECUTION_PLAN.md`.
- This is all configurable via environment variables; see [configuration.md](configuration.md).

**Blocked Plans**
- Blocked-doc detection checks for the presence of the plan and spec under `.ralph/plans/blocked/` by default. 
- If blocked docs are present, Ralph feeds `.ralph/prompts/blocked.md` to the AI Agent in interactive mode.  

---

**Next:** [logging.md](logging.md) - Log files, unattended logging, and error capture.
