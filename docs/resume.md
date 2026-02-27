# Resume

Ralph can resume existing AI sessions instead of starting fresh ones.

**Resume Mode**
- `--resume` enables resume behavior on the first main-loop pass only.
- If `--resume` includes a session ID, Ralph passes that ID through for either tool:
  - Codex interactive: `codex resume <id>` (no prompt argument)
  - Codex unattended execute: `codex exec resume <id> continue`
  - Claude interactive: `claude --resume <id>` (no prompt argument)
  - Claude unattended execute: `claude --resume <id> -p continue`
- If `--resume` does not include a session ID, Ralph resumes the latest session:
  - Codex interactive: `codex resume --last` (no prompt argument)
  - Codex unattended execute: `codex exec resume --last continue`
  - Claude interactive: `claude --continue` (no prompt argument)
  - Claude unattended execute: `claude --continue -p continue`
- After the first pass, Ralph clears resume mode and continues normal loop behavior.

**Handoff Resume Behavior**
- For Codex, handoff uses `codex exec resume <id> <prompt>` when a session ID is available.
- If no session ID is found, handoff falls back to `codex exec resume --last <prompt>`.
- For Claude, handoff uses `claude --continue <prompt>`.
- Codex session IDs are extracted from `ERROR_LOG` by searching for the latest `session id:` line.

---

**Next:** [callbacks.md](callbacks.md) - Deterministic backpressure via post-pass validation scripts.
