# Interrupts (Ctrl+C)

Ralph delegates most interrupt behavior to the underlying agent, but it does enforce some exit rules.

**Interactive Mode**
- Codex CLI: first Ctrl+C stops the current operation and returns to input; a second Ctrl+C exits Codex.
- Claude CLI: any Ctrl+C exits Claude immediately.
- When the agent exits with SIGINT (exit code 130), Ralph exits its loop.

**Non-Interactive Mode**
- In unattended mode, Ralph wraps the agent with a SIGINT trap that exits immediately.
- If the log output includes the phrase "task interrupted", Ralph exits cleanly.

**Loop Exit**
- Repeated Ctrl+C will eventually break Ralph out of its loop even if the agent handles the first interrupt.
