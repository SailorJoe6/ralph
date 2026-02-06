# Permissions

Both Claude and Codex require explicit approval for potentially dangerous actions (file writes, command execution, etc.). In a normal interactive session, the AI pauses and waits for the human to approve each action. Ralph's permission modes elevate these permissions so the AI can work autonomously.

## Modes

### No flags (default)

No extra permission flags are passed. The AI prompts for approval on each action. Use this when you want full control over every step.

### `--yolo`

Elevated permissions **with** interactive control. The AI runs with full permissions but stops at the end of each pass, waiting for you to press Ctrl+C to exit or let it continue. You stay in the loop — you can watch the AI work, provide feedback between passes, and intervene if something goes wrong.

**When to use:** Start here. Use `--yolo` any time you're not 100% sure the plan is airtight, or when you want to observe the AI's behavior on a new task. It gives you speed without giving up oversight.

### `--unattended`

Elevated permissions **without** interactive control. The AI loops continuously until it either completes the plan (moving it to "archived") or becomes blocked and cannot unblock itself. No human intervention is expected or possible between passes.

**When to use:** Once you trust the plan and have seen the AI execute similar work successfully. Use `--unattended` when you want to step away — go to dinner, the movies, or to bed — and let Ralph work through the plan on its own. Pair with `--callback` for deterministic guardrails (see [callbacks.md](callbacks.md)).

**Restrictions:**
- CLI-only (cannot be enabled via `.env` or environment variables).
- Only works with the execute phase (not freestyle mode).
- Cannot be combined with `--yolo`.

## Under the Hood

When `--yolo` or `--unattended` is set, Ralph passes:
- Codex: `--dangerously-bypass-approvals-and-sandbox`
- Claude: `--dangerously-skip-permissions`

Without either flag, no extra permission flags are passed to the AI.
