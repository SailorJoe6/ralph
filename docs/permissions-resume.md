# Permissions, Resume, And Safety Controls

Ralph can elevate agent permissions and resume existing sessions for both Codex and Claude.

**Permission Flags**
- When `--yolo` or `--unattended` is set, Ralph adds:
- Codex: `--dangerously-bypass-approvals-and-sandbox`
- Claude: `--dangerously-skip-permissions`
- Without those flags, no extra permission flags are passed.

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

**Unattended Mode**
- `--unattended` only affects execute and handoff phases and runs them non-interactively.
- Freestyle mode cannot run unattended.
