# Resume

Ralph can resume existing AI sessions instead of starting fresh ones.

**Resume Mode**
- `--resume` enables resume behavior.
- For Codex, `--resume` optionally accepts a session ID. This is passed as `codex --resume` or `codex --resume <id>`.
- For Claude, `--resume` is allowed only without a session ID and maps to `claude --continue`.
- If a session ID is provided without `--codex`, Ralph exits with an error.

**Handoff Resume Behavior**
- For Codex, handoff uses `codex exec resume <id> <prompt>` when a session ID is available.
- If no session ID is found, handoff falls back to `codex exec resume --last <prompt>`.
- For Claude, handoff uses `claude --continue <prompt>`.
- Codex session IDs are extracted from `ERROR_LOG` by searching for the latest `session id:` line.
