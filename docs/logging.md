# Logging

Ralph records error output consistently and logs full output in unattended mode.

**Log Files**
- `ERROR_LOG` captures stderr from the agent. It is overwritten on each main pass.  
- `OUTPUT_LOG` captures stdout (and prints some headers) in unattended mode and is appended to across passes so you can see how Ralph is progressing.

**Interactive Behavior**
- In interactive mode, stdout goes to the terminal.
- Stderr from the main pass is written to `ERROR_LOG` (overwriting the file).

**Unattended Behavior**
- In unattended mode, Ralph writes a pass header to `OUTPUT_LOG` and appends agent output.
- `ERROR_LOG` is overwritten per pass.  It's worth noting that codex outputs all of it's reasoning on stderr whenever it's in a non-interactive mode.  Claude has no similar capability.  
- If the new error log output contains interrupt markers (case-insensitive "task interrupted", "interrupted", "sigint", "signal 2"), Ralph exits cleanly. This is a workaround for CLI signal handling quirks in non-interactive mode.

---

**Next:** [permissions.md](permissions.md) - Permission elevation and unattended safety controls.
