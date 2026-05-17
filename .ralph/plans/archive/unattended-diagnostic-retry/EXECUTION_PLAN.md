# Execution Plan: Codex Non-Zero Exit Diagnostics & Retry

## Overview

Add structured diagnostic capture and retry-with-backoff to the unattended execute loop in `start`. The change touches one file (`start`) and adds one test script.

## Architecture

The current error handling at lines 680–688 of `start` is a simple "print and exit". We replace it (in the `NONINTERACTIVE` path only) with:

1. A `capture_diagnostic` function that writes a structured block to `EXECUTION_LOG`
2. A retry loop around the existing execute command with hardcoded exponential backoff
3. A final summary diagnostic if all retries fail

Interactive mode error handling remains unchanged.

---

## Status

All steps complete. Implementation verified with full test suite passing.

## Steps

### Step 1: Add `capture_diagnostic` helper function ✅

**Location:** Insert after `interrupt_detected_in_output_log()` (after line 458), before `run_codex()`.

**Function signature:**
```bash
capture_diagnostic() {
  local pass="$1"
  local attempt="$2"
  local exit_code="$3"
  local error_log="$4"
  local error_offset="$5"
  local execution_log="$6"
  local output_offset="$7"
}
```

**Responsibilities:**
- Write `--- DIAGNOSTIC (pass N, attempt M) ---` delimiter to EXECUTION_LOG
- ISO 8601 timestamp
- Exit code with signal name mapping (137→SIGKILL, 139→SIGSEGV, 143→SIGTERM, 134→SIGABRT, 127→command not found)
- New content from ERROR_LOG since `error_offset` (using `tail -c`)
- Last 20 lines of EXECUTION_LOG output from this pass (using `tail -c` from `output_offset`, then `tail -20`)
- CLI version (`codex --version` or `claude --version` depending on `USE_CODEX`)
- Disk usage: `df -h .` (one line)
- Memory: `vm_stat` on macOS, head of `/proc/meminfo` on Linux
- Load average: `uptime`
- Write `--- END DIAGNOSTIC ---` delimiter

**Design note:** The function appends directly to `EXECUTION_LOG` (the caller redirects stdout to it in unattended mode, so we just echo). We'll pass the log file path explicitly and append with `>>` inside the function to keep it self-contained.

### Step 2: Add `map_signal_name` helper ✅

**Location:** Immediately before `capture_diagnostic`.

```bash
map_signal_name() {
  local code="$1"
  case "$code" in
    127) echo "command not found" ;;
    130) echo "SIGINT" ;;
    134) echo "SIGABRT" ;;
    137) echo "SIGKILL" ;;
    139) echo "SIGSEGV" ;;
    143) echo "SIGTERM" ;;
    *)   echo "" ;;
  esac
}
```

### Step 3: Refactor the unattended execute block to support retry ✅

**Current code (lines 640–688):**
```bash
if [[ $NONINTERACTIVE -eq 1 ]]; then
  error_offset=0
  output_offset=0
  ...
  # run codex/claude
  ...
fi
status=$?
...
if [[ $status -ne 0 ]]; then
  echo "Codex exited with status $status"
  cat "$ERROR_LOG"
  exit 1
fi
```

**New structure:**

Replace lines 640–688 with:

```bash
if [[ $NONINTERACTIVE -eq 1 ]]; then
  MAX_ATTEMPTS=4
  BACKOFF_DELAYS=(0 5 15 45)
  attempt=1

  while [[ $attempt -le $MAX_ATTEMPTS ]]; do
    if [[ $attempt -gt 1 ]]; then
      sleep "${BACKOFF_DELAYS[$((attempt - 1))]}"
    fi

    error_offset=0
    output_offset=0
    if [[ -f "$ERROR_LOG" ]]; then
      error_offset=$(wc -c < "$ERROR_LOG")
    fi
    if [[ -f "$EXECUTION_LOG" ]]; then
      output_offset=$(wc -c < "$EXECUTION_LOG")
    fi

    {
      printf '\n---\n\nPass %d (attempt %d):\n' "$PASS" "$attempt"
      if [[ $USE_CODEX -eq 1 ]]; then
        run_codex 1 "$prompt_text"
      else
        run_claude 1 "$prompt_text"
      fi
    } >> "$EXECUTION_LOG" 2> "$ERROR_LOG"
    status=$?
    RESUME_PENDING=0

    # Check for interrupt patterns — never retry interrupts
    if [[ -f "$ERROR_LOG" ]]; then
      if interrupt_detected_in_error_log "$ERROR_LOG" "$error_offset"; then
        exit 0
      fi
    fi
    if [[ -f "$EXECUTION_LOG" ]]; then
      if interrupt_detected_in_output_log "$EXECUTION_LOG" "$output_offset"; then
        exit 0
      fi
    fi
    if [[ $status -eq 130 ]]; then
      exit 0
    fi

    # Success — break out of retry loop
    if [[ $status -eq 0 ]]; then
      break
    fi

    # Failure — capture diagnostic
    capture_diagnostic "$PASS" "$attempt" "$status" "$ERROR_LOG" "$error_offset" "$EXECUTION_LOG" "$output_offset"

    attempt=$((attempt + 1))
  done

  # All retries exhausted
  if [[ $status -ne 0 ]]; then
    printf '\n--- FINAL: All %d attempts failed for pass %d. Exiting. ---\n' "$MAX_ATTEMPTS" "$PASS" >> "$EXECUTION_LOG"
    exit 1
  fi

else
  # Interactive mode — unchanged
  if [[ $USE_CODEX -eq 1 ]]; then
    run_codex 0 "$prompt_text" 2> "$ERROR_LOG"
  else
    run_claude 0 "$prompt_text" 2> "$ERROR_LOG"
  fi
  status=$?
  RESUME_PENDING=0

  if [[ $status -eq 130 ]]; then
    exit 0
  fi
  if [[ $status -ne 0 ]]; then
    if [[ $USE_CODEX -eq 1 ]]; then
      echo "Codex exited with status $status"
    else
      echo "Claude exited with status $status"
    fi
    cat "$ERROR_LOG"
    exit 1
  fi
fi
```

**Key changes:**
- The interrupt detection and exit-code-130 checks move INSIDE the retry loop (per spec: "Exit code 130 is never retried")
- First attempt has no delay (`BACKOFF_DELAYS[0]=0`)
- Pass header now shows attempt number for traceability (only in unattended — won't confuse interactive logs)
- Interactive branch is structurally unchanged, just moved into the `else` clause
- The existing interrupt detection code at lines 666–678 is absorbed into the retry loop

### Step 4: Remove now-redundant post-execute checks ✅

The old lines 664–688 (post-execute status check, interrupt detection, and error exit) are replaced by the logic inside the retry loop and the interactive `else` branch. Remove them entirely — the new structure handles all cases.

### Step 5: Add test script `tests/test_diagnostic_retry.sh` ✅

A shell test that validates:
1. **Diagnostic capture format** — Mock a failing command, verify the diagnostic block appears in the execution log with correct delimiters
2. **Retry count** — Verify exactly 4 attempts occur when all fail
3. **No retry on exit 130** — Verify immediate exit on SIGINT code
4. **No retry in interactive mode** — Verify immediate exit on non-zero in interactive mode
5. **Success on retry** — Mock a command that fails twice then succeeds, verify loop exits after attempt 3

**Approach:** Source the helper functions from `start` (or extract them into a testable lib if needed), mock `run_codex`/`run_claude` with a simple script that returns configurable exit codes.

### Step 6: Run existing tests for regression ✅

Run all existing test scripts to ensure nothing breaks:
```bash
bash tests/test_cli_dispatch.sh
bash tests/test_config_precedence.sh
bash tests/test_runtime_root_enforcement.sh
bash tests/test_phase8_runtime_validation.sh
bash tests/test_init_v2.sh
bash tests/test_upgrade_v2.sh
bash tests/test_install_v2.sh
```

---

## Constraints

- No new `.env` variables — backoff values are hardcoded
- No changes to handoff error handling
- No changes to interactive mode behavior (other than structural refactor into `else` branch)
- No changes to `ralph` dispatcher, `init`, or `upgrade`
- Signal mapping is best-effort (unknown signals show numeric code only)
- `capture_diagnostic` is defensive — each system-state command uses `|| true` to avoid breaking on missing utilities

## Verification

- Existing test suite passes
- New test script validates diagnostic format, retry behavior, and interrupt bypass
- Manual smoke test: `ralph --unattended` with a deliberately broken Codex/Claude path to observe diagnostic + retry output in EXECUTION_LOG
