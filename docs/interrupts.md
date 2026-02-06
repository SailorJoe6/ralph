# Interrupts (Ctrl+C)

The only way to exit Ralph's loop is Ctrl+C. However, because Ralph runs an AI agent inside its loop, Ctrl+C passes through several layers before reaching Ralph itself.

## How It Works

Ralph runs in a loop: launch the agent, wait for it to finish, launch it again. When you press Ctrl+C, the signal goes to the **innermost process first** — the AI agent — not to Ralph.

### Interactive Mode

1. **First Ctrl+C** — Interrupts the AI agent (Claude or Codex). Both CLIs treat this as "stop the current operation" and return to their input prompt.
2. **Second Ctrl+C** — Exits the AI agent entirely. The agent process ends and returns control to Ralph.  (Note that this is the default behavior of Codex/Claude.  Nothing changed about this)
3. **Ralph continues** — Ralph sees the agent exited and moves to the next step in its workflow (e.g., handoff). It does not stop.
4. **Keep pressing Ctrl+C** — You need to repeat the process to break through each subsequent step. Eventually Ralph's own INT trap fires and it exits cleanly.

In short: exiting the AI agent (whether via Ctrl+C, `/exit`, or any other means) does **not** exit Ralph. Ralph just moves on. You must press Ctrl+C repeatedly to break out of the entire Ralph loop.

### Non-Interactive (Unattended) Mode

- Ralph wraps the agent with a SIGINT trap that kills the process immediately.
- If the log output includes the phrase "task interrupted", Ralph exits cleanly.
- Exit code 130 (SIGINT) from the agent causes Ralph to exit its loop.
