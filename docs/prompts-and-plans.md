# Skills And Planning Docs

The ralph script selects skill instructions to feed into Claude or Codex in order to control the execution flow.

**Runtime Skill Lookup**
`ralph` reads active skill files from `<project_root>/.ralph/skills/<phase>/SKILL.md` by default. Legacy projects with `.ralph/prompts/` and no `.ralph/skills/` remain runtime-compatible until they are upgraded.

Required skill files:
- `.ralph/skills/design/SKILL.md`
- `.ralph/skills/plan/SKILL.md`
- `.ralph/skills/execute/SKILL.md`
- `.ralph/skills/handoff/SKILL.md`
- `.ralph/skills/prepare/SKILL.md`
- `.ralph/skills/blocked/SKILL.md`

**Skill Templates**
- Non-beads template files live in `~/.local/share/ralph/skills/*.example.md`.
- Beads variants live in `~/.local/share/ralph/skills/*.example.beads.md` where available.
- `ralph init` copies templates into `<project_root>/.ralph/skills/<phase>/SKILL.md`, preserving any existing destination files.
- Runtime strips a leading YAML frontmatter block before forwarding instruction text to Claude or Codex, so both skill files and plain legacy prompts remain valid.
- These default skills reference V2 planning paths under `.ralph/plans/...`, so if you choose to customize their locations, update the skills too!
- If a required runtime instruction file is missing, `ralph` exits and prints creation guidance.

**Planning Docs**
- The ralph scriot chooses which mode to enter on every iteration in accordance with the location of `SPECIFICATION.md` and `EXECUTION_PLAN.md`.
    - when neither file exists, Ralph feeds the design skill to Claude or Codex in interactive mode.
    - when only `SPECIFICATION.md` exists, Ralph feeds the plan skill to Claude or Codex in interactive mode.
    - when both files exist, Ralph feeds the execute skill to Claude or Codex.  Flags control whether this happens in interactive or unattended mode.

- By default, these plan files are expected at `.ralph/plans/SPECIFICATION.md` and `.ralph/plans/EXECUTION_PLAN.md`.
- This is all configurable via environment variables; see [configuration.md](configuration.md).

**Blocked Plans**
- Blocked-doc detection checks for the presence of the plan and spec under `.ralph/plans/blocked/` (recursively, including subfolders) by default. 
- If blocked docs are present, Ralph feeds `.ralph/skills/blocked/SKILL.md` to the AI Agent in interactive mode.

---

**Next:** [logging.md](logging.md) - Log files, unattended logging, and error capture.
