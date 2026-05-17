# Codex Non-Zero Exit Diagnostics & Retry

## Problem

When running in unattended mode, Codex frequently exits with a non-zero status but provides no indication of why. The current behavior (lines 680-688 of `start`) prints the exit code, dumps the error log (often empty), and hard-exits. This interrupts the ralph loop with no forensic data for debugging.

## Current Behavior

```bash
if [[ $status -ne 0 ]]; then
  echo "Codex exited with status $status"
  cat "$ERROR_LOG"
  exit 1
fi
```

- No diagnostic context is captured to EXECUTION_LOG
- No retry is attempted for transient failures
- The loop dies immediately, requiring manual restart

## Required Changes

### 1. Diagnostic Block on Non-Zero Exit (Unattended Mode)

When Codex (or Claude) exits non-zero in unattended mode, write a structured diagnostic block to `EXECUTION_LOG` before deciding whether to retry or exit. The block must include:

**Codex-specific info:**
- Timestamp (ISO 8601)
- Exit code (numeric)
- Signal name mapping (e.g., 137 → SIGKILL, 139 → SIGSEGV, 143 → SIGTERM)
- Contents of ERROR_LOG (the new content since this pass started, using the existing `error_offset` mechanism)
- Last 20 lines of EXECUTION_LOG output from this pass
- `codex --version` output (or `claude --version` when using Claude)

**System state:**
- Disk usage (`df -h .` or equivalent one-liner)
- Available memory (`vm_stat` on macOS, `/proc/meminfo` on Linux — pick what's available)
- Load average (`uptime` or equivalent)

**Format:** The diagnostic block should be clearly delimited in the log so it's easy to find:

```
--- DIAGNOSTIC (pass N, attempt M) ---
Timestamp: 2026-05-17T14:32:01-0700
Exit code: 137 (SIGKILL)
...
--- END DIAGNOSTIC ---
```

### 2. Retry with Exponential Backoff (Unattended Mode Only)

After capturing diagnostics, retry the failed pass up to **3 times** (4 total attempts) with exponential backoff:

| Attempt | Delay before retry |
|---------|-------------------|
| 1 (original) | — |
| 2 (1st retry) | 5 seconds |
| 3 (2nd retry) | 15 seconds |
| 4 (3rd retry) | 45 seconds |

**Retry rules:**
- Only applies in unattended mode (`NONINTERACTIVE=1`)
- Interactive mode behavior is unchanged — still exits immediately on non-zero
- Each retry attempt gets its own diagnostic block if it also fails
- Exit code 130 (SIGINT / user interrupt) is never retried (existing behavior preserved)
- Interrupt patterns detected in error/output logs are never retried (existing behavior preserved)
- After all retries exhausted, write a final summary diagnostic and exit 1

**Backoff values are hardcoded** — no .env configuration needed.

### 3. Scope

- Applies to the main execute pass in the unattended code path (the `NONINTERACTIVE=1` branch around lines 649-656)
- Does NOT apply to the handoff phase (handoff failures are already treated as non-fatal)
- Does NOT apply to interactive mode
- The diagnostic function should work for both Codex and Claude (use appropriate version command)

## Files to Modify

- `start` — the main runtime script where the execute loop and error handling live

## Non-Goals

- No changes to the handoff retry/error behavior
- No changes to interactive mode error handling
- No new configuration variables
- No changes to the `ralph` dispatcher or other scripts
