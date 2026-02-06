# Logging

Ralph records error output consistently and captures full output in unattended mode.

**Log Files**
- `ERROR_LOG` captures stderr from the agent. It is overwritten on each main pass.
- `OUTPUT_LOG` captures stdout and pass headers in unattended mode and is appended to across passes.

**Interactive Behavior**
- In interactive mode, stdout goes to the terminal.
- Stderr from the main pass is written to `ERROR_LOG` (overwriting the file).
- Codex handoff in interactive mode appends to `ERROR_LOG` via `tee -a`.
- Claude handoff in interactive mode writes to the terminal only (no error-log capture).

**Unattended Behavior**
- In unattended mode, Ralph writes a pass header to `OUTPUT_LOG` and appends agent output.
- `ERROR_LOG` is overwritten per pass.
- If the new log output contains "task interrupted", Ralph exits cleanly.
