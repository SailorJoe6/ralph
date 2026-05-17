# Logging

Ralph records error output consistently and logs full output in unattended mode.

**Log Files**
- `ERROR_LOG` captures stderr from the agent. It is overwritten on each main pass.  
- `EXECUTION_LOG` captures stdout (and prints some headers) in unattended mode and is appended to across passes so you can see how Ralph is progressing.

**Interactive Behavior**
- In interactive mode, stdout goes to the terminal.
- Stderr from the main pass is written to `ERROR_LOG` (overwriting the file).

**Unattended Behavior**
- In unattended mode, Ralph writes a pass header to `EXECUTION_LOG` and appends agent output.
- `ERROR_LOG` is overwritten per pass.  It's worth noting that codex outputs all of it's reasoning on stderr whenever it's in a non-interactive mode.  Claude has no similar capability.  
- If the new error log output contains interrupt markers (case-insensitive "task interrupted", "interrupted", "sigint", "signal 2"), Ralph exits cleanly. This is a workaround for CLI signal handling quirks in non-interactive mode.

**Retry with Diagnostics (Unattended Only)**

When the agent exits with a non-zero status in unattended mode, Ralph captures a structured diagnostic block to `EXECUTION_LOG` and retries the failed pass up to 3 times (4 total attempts) with exponential backoff:

| Attempt | Delay before retry |
|---------|-------------------|
| 1 (original) | — |
| 2 (1st retry) | 5 seconds |
| 3 (2nd retry) | 15 seconds |
| 4 (3rd retry) | 45 seconds |

Each failed attempt produces a diagnostic block in `EXECUTION_LOG`:

```
--- DIAGNOSTIC (pass N, attempt M) ---
Timestamp: 2026-05-17T14:32:01+0000
Exit code: 137 (SIGKILL)
CLI version: codex 0.1.0
Error log (new content): ...
Last 20 lines of output from this pass: ...
Disk usage: ...
Memory: ...
Load: ...
--- END DIAGNOSTIC ---
```

After all retries are exhausted, Ralph writes a final summary and exits 1:
```
--- FINAL: All 4 attempts failed for pass N. Exiting. ---
```

Retry rules:
- Exit code 130 (SIGINT) is never retried.
- Interrupt patterns in error/output logs are never retried.
- Interactive mode is unaffected — it still exits immediately on non-zero.
- Backoff values are hardcoded (not configurable).

---

**Next:** [permissions.md](permissions.md) - Permission elevation and unattended safety controls.
