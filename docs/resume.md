# Resume

Ralph can resume existing AI sessions instead of starting fresh ones.

**Resume Mode**
- `--resume` enables resume behavior on the first main-loop pass only.
- If `--resume` includes a session ID, Ralph passes that ID through for either tool:
  - Codex interactive: `codex resume <id> <prompt>`
  - Codex unattended execute: `codex exec resume <id> <prompt>`
  - Claude: `claude --resume <id> ...`
- If `--resume` does not include a session ID, Ralph resumes the latest session:
  - Codex interactive: `codex resume --last <prompt>`
  - Codex unattended execute: `codex exec resume --last <prompt>`
  - Claude: `claude --continue ...`
- After the first pass, Ralph clears resume mode and continues normal loop behavior.

**Handoff Resume Behavior**
- For Codex, handoff uses `codex exec resume <id> <prompt>` when a session ID is available.
- If no session ID is found, handoff falls back to `codex exec resume --last <prompt>`.
- For Claude, handoff uses `claude --continue <prompt>`.
- Codex session IDs are extracted from `ERROR_LOG` by searching for the latest `session id:` line.
