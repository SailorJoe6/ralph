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
- If the new log output contains "task interrupted", Ralph exits cleanly.  This is a workaround to Codex swallowing CTRL+C sequences when in non-interactive mode, but reliably sending "task interrupted" to stderr in these circumstances. 

---

**Next:** [permissions.md](permissions.md) - Permission elevation and unattended safety controls.
