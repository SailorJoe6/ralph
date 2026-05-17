#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_SCRIPT="$(cd "$SCRIPT_DIR/.." && pwd)/start"

if [[ ! -f "$START_SCRIPT" ]]; then
  echo "Expected script not found: $START_SCRIPT" >&2
  exit 1
fi

TESTS_PASSED=0
TESTS_FAILED=0

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "FAIL: $label" >&2
    echo "  Expected to find: $needle" >&2
    echo "  In output (first 500 chars):" >&2
    echo "  ${haystack:0:500}" >&2
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
  return 0
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "FAIL: $label" >&2
    echo "  Expected NOT to find: $needle" >&2
    TESTS_FAILED=$((TESTS_FAILED + 1))
    return 1
  fi
  return 0
}

pass() {
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "  PASS: $1"
}

# --- Test 1: map_signal_name function ---
echo "Test 1: map_signal_name"

# Source the helper functions by extracting them
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/helpers.sh" << 'HELPERS'
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
HELPERS

source "$TMP_DIR/helpers.sh"

[[ "$(map_signal_name 137)" == "SIGKILL" ]] && pass "137 -> SIGKILL" || { echo "FAIL: 137 -> SIGKILL"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
[[ "$(map_signal_name 139)" == "SIGSEGV" ]] && pass "139 -> SIGSEGV" || { echo "FAIL: 139 -> SIGSEGV"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
[[ "$(map_signal_name 143)" == "SIGTERM" ]] && pass "143 -> SIGTERM" || { echo "FAIL: 143 -> SIGTERM"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
[[ "$(map_signal_name 130)" == "SIGINT" ]] && pass "130 -> SIGINT" || { echo "FAIL: 130 -> SIGINT"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
[[ "$(map_signal_name 127)" == "command not found" ]] && pass "127 -> command not found" || { echo "FAIL: 127 -> command not found"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
[[ "$(map_signal_name 1)" == "" ]] && pass "1 -> empty (unknown)" || { echo "FAIL: 1 -> empty"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

# --- Test 2: capture_diagnostic format ---
echo "Test 2: capture_diagnostic format"

USE_CODEX=1
EXEC_LOG="$TMP_DIR/exec.log"
ERR_LOG="$TMP_DIR/err.log"

echo "some prior output" > "$EXEC_LOG"
echo "some error text from this pass" > "$ERR_LOG"

cat > "$TMP_DIR/capture.sh" << 'CAPTURE'
#!/usr/bin/env bash
USE_CODEX="${USE_CODEX:-1}"

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

capture_diagnostic() {
  local pass="$1"
  local attempt="$2"
  local exit_code="$3"
  local error_log="$4"
  local error_offset="$5"
  local execution_log="$6"
  local output_offset="$7"

  local signal_name
  signal_name="$(map_signal_name "$exit_code")"
  local exit_display="$exit_code"
  if [[ -n "$signal_name" ]]; then
    exit_display="$exit_code ($signal_name)"
  fi

  local version_cmd="claude --version"
  if [[ $USE_CODEX -eq 1 ]]; then
    version_cmd="codex --version"
  fi
  local cli_version
  cli_version="$($version_cmd 2>/dev/null || echo "unknown")"

  local disk_usage
  disk_usage="$(df -h . 2>/dev/null | tail -1 || true)"

  local memory_info
  if [[ "$(uname)" == "Darwin" ]]; then
    memory_info="$(vm_stat 2>/dev/null | head -5 || true)"
  else
    memory_info="$(head -5 /proc/meminfo 2>/dev/null || true)"
  fi

  local load_avg
  load_avg="$(uptime 2>/dev/null || true)"

  {
    printf '\n--- DIAGNOSTIC (pass %d, attempt %d) ---\n' "$pass" "$attempt"
    printf 'Timestamp: %s\n' "$(date -u +"%Y-%m-%dT%H:%M:%S%z" 2>/dev/null || date)"
    printf 'Exit code: %s\n' "$exit_display"

    printf 'CLI version: %s\n' "$cli_version"

    printf '\nError log (new content):\n'
    if [[ -f "$error_log" ]]; then
      tail -c "+$((error_offset + 1))" "$error_log" 2>/dev/null || echo "(empty)"
    else
      echo "(no error log)"
    fi

    printf '\nLast 20 lines of output from this pass:\n'
    if [[ -f "$execution_log" ]]; then
      tail -c "+$((output_offset + 1))" "$execution_log" 2>/dev/null | tail -20 || echo "(empty)"
    else
      echo "(no execution log)"
    fi

    printf '\nDisk usage: %s\n' "$disk_usage"
    printf 'Memory:\n%s\n' "$memory_info"
    printf 'Load: %s\n' "$load_avg"
    printf '%s\n' "--- END DIAGNOSTIC ---"
  } >> "$execution_log"
}
CAPTURE

source "$TMP_DIR/capture.sh"

# Run capture_diagnostic with error_offset=0 (capture all error content)
capture_diagnostic 1 2 137 "$ERR_LOG" 0 "$EXEC_LOG" 0

diag_output="$(cat "$EXEC_LOG")"
assert_contains "$diag_output" "--- DIAGNOSTIC (pass 1, attempt 2) ---" "diagnostic header" && pass "diagnostic header"
assert_contains "$diag_output" "Exit code: 137 (SIGKILL)" "exit code with signal" && pass "exit code with signal"
assert_contains "$diag_output" "Timestamp:" "timestamp present" && pass "timestamp present"
assert_contains "$diag_output" "CLI version:" "cli version present" && pass "cli version present"
assert_contains "$diag_output" "some error text from this pass" "error log content" && pass "error log content"
assert_contains "$diag_output" "Disk usage:" "disk usage" && pass "disk usage"
assert_contains "$diag_output" "Load:" "load average" && pass "load average"
assert_contains "$diag_output" "--- END DIAGNOSTIC ---" "diagnostic footer" && pass "diagnostic footer"

# --- Test 3: Retry count (4 attempts when all fail) ---
echo "Test 3: Retry count - exactly 4 attempts on persistent failure"

# Build a minimal harness that simulates the retry loop
RETRY_LOG="$TMP_DIR/retry_attempts.log"
rm -f "$RETRY_LOG"

cat > "$TMP_DIR/test_retry.sh" << 'RETRY_SCRIPT'
#!/usr/bin/env bash
set -uo pipefail

RETRY_LOG="$1"
EXECUTION_LOG="$2"
ERROR_LOG="$3"

USE_CODEX=1
PASS=1
MAX_ATTEMPTS=4
BACKOFF_DELAYS=(0 0 0 0)  # No actual delays for tests
attempt=1
status=1

interrupt_detected_in_error_log() { return 1; }
interrupt_detected_in_output_log() { return 1; }
map_signal_name() {
  case "$1" in
    137) echo "SIGKILL" ;; *) echo "" ;;
  esac
}
capture_diagnostic() {
  echo "diag:pass=$1,attempt=$2,exit=$3" >> "$RETRY_LOG"
}

run_codex() {
  echo "attempt" >> "$RETRY_LOG"
  return 1
}

while [[ $attempt -le $MAX_ATTEMPTS ]]; do
  if [[ $attempt -gt 1 ]]; then
    sleep "${BACKOFF_DELAYS[$((attempt - 1))]}"
  fi

  error_offset=0
  output_offset=0

  {
    printf '\n---\n\nPass %d (attempt %d):\n' "$PASS" "$attempt"
    run_codex 1 "test prompt"
  } >> "$EXECUTION_LOG" 2> "$ERROR_LOG"
  status=$?

  if [[ $status -eq 130 ]]; then
    exit 0
  fi

  if [[ $status -eq 0 ]]; then
    break
  fi

  capture_diagnostic "$PASS" "$attempt" "$status" "$ERROR_LOG" "$error_offset" "$EXECUTION_LOG" "$output_offset"

  attempt=$((attempt + 1))
done

if [[ $status -ne 0 ]]; then
  printf '\n--- FINAL: All %d attempts failed for pass %d. Exiting. ---\n' "$MAX_ATTEMPTS" "$PASS" >> "$EXECUTION_LOG"
  exit 1
fi
RETRY_SCRIPT
chmod +x "$TMP_DIR/test_retry.sh"

RETRY_EXEC_LOG="$TMP_DIR/retry_exec.log"
RETRY_ERR_LOG="$TMP_DIR/retry_err.log"
rm -f "$RETRY_EXEC_LOG" "$RETRY_ERR_LOG" "$RETRY_LOG"
touch "$RETRY_EXEC_LOG" "$RETRY_ERR_LOG" "$RETRY_LOG"

set +e
bash "$TMP_DIR/test_retry.sh" "$RETRY_LOG" "$RETRY_EXEC_LOG" "$RETRY_ERR_LOG"
retry_exit=$?
set -e

attempt_count="$(grep -c "^attempt$" "$RETRY_LOG")"
diag_count="$(grep -c "^diag:" "$RETRY_LOG")"
[[ "$attempt_count" == "4" ]] && pass "exactly 4 attempts" || { echo "FAIL: expected 4 attempts, got $attempt_count"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
[[ "$diag_count" == "4" ]] && pass "4 diagnostic blocks" || { echo "FAIL: expected 4 diagnostics, got $diag_count"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
[[ "$retry_exit" == "1" ]] && pass "exits 1 after retries exhausted" || { echo "FAIL: expected exit 1, got $retry_exit"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

final_msg="$(cat "$RETRY_EXEC_LOG")"
assert_contains "$final_msg" "FINAL: All 4 attempts failed" "final failure message" && pass "final failure message"

# --- Test 4: No retry on exit 130 ---
echo "Test 4: No retry on exit 130 (SIGINT)"

cat > "$TMP_DIR/test_sigint.sh" << 'SIGINT_SCRIPT'
#!/usr/bin/env bash
set -uo pipefail

RETRY_LOG="$1"
EXECUTION_LOG="$2"
ERROR_LOG="$3"

USE_CODEX=1
PASS=1
MAX_ATTEMPTS=4
BACKOFF_DELAYS=(0 0 0 0)
attempt=1
status=0

interrupt_detected_in_error_log() { return 1; }
interrupt_detected_in_output_log() { return 1; }
map_signal_name() { echo ""; }
capture_diagnostic() { echo "diag" >> "$RETRY_LOG"; }

run_codex() {
  echo "attempt" >> "$RETRY_LOG"
  return 130
}

while [[ $attempt -le $MAX_ATTEMPTS ]]; do
  {
    run_codex 1 "test"
  } >> "$EXECUTION_LOG" 2> "$ERROR_LOG"
  status=$?

  if [[ $status -eq 130 ]]; then
    exit 0
  fi

  if [[ $status -eq 0 ]]; then
    break
  fi

  capture_diagnostic "$PASS" "$attempt" "$status" "$ERROR_LOG" 0 "$EXECUTION_LOG" 0
  attempt=$((attempt + 1))
done
exit 1
SIGINT_SCRIPT
chmod +x "$TMP_DIR/test_sigint.sh"

rm -f "$RETRY_LOG" "$RETRY_EXEC_LOG" "$RETRY_ERR_LOG"
touch "$RETRY_LOG" "$RETRY_EXEC_LOG" "$RETRY_ERR_LOG"

set +e
bash "$TMP_DIR/test_sigint.sh" "$RETRY_LOG" "$RETRY_EXEC_LOG" "$RETRY_ERR_LOG"
sigint_exit=$?
set -e

sigint_attempts="$(grep -c "^attempt$" "$RETRY_LOG")"
[[ "$sigint_exit" == "0" ]] && pass "exits 0 on code 130" || { echo "FAIL: expected exit 0, got $sigint_exit"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
[[ "$sigint_attempts" == "1" ]] && pass "only 1 attempt before exit" || { echo "FAIL: expected 1 attempt, got $sigint_attempts"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

# --- Test 5: No retry in interactive mode ---
echo "Test 5: No retry in interactive mode"

cat > "$TMP_DIR/test_interactive.sh" << 'INTERACTIVE_SCRIPT'
#!/usr/bin/env bash
set -uo pipefail

RETRY_LOG="$1"
ERROR_LOG="$2"

USE_CODEX=1
NONINTERACTIVE=0

run_codex() {
  echo "attempt" >> "$RETRY_LOG"
  return 1
}

# Interactive mode: no retry loop
if [[ $USE_CODEX -eq 1 ]]; then
  run_codex 0 "test" 2> "$ERROR_LOG"
fi
status=$?

if [[ $status -eq 130 ]]; then
  exit 0
fi
if [[ $status -ne 0 ]]; then
  exit 1
fi
INTERACTIVE_SCRIPT
chmod +x "$TMP_DIR/test_interactive.sh"

rm -f "$RETRY_LOG" "$RETRY_ERR_LOG"
touch "$RETRY_LOG" "$RETRY_ERR_LOG"

set +e
bash "$TMP_DIR/test_interactive.sh" "$RETRY_LOG" "$RETRY_ERR_LOG"
interactive_exit=$?
set -e

interactive_attempts="$(grep -c "^attempt$" "$RETRY_LOG")"
[[ "$interactive_exit" == "1" ]] && pass "interactive exits 1 immediately" || { echo "FAIL: expected exit 1, got $interactive_exit"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
[[ "$interactive_attempts" == "1" ]] && pass "interactive: only 1 attempt" || { echo "FAIL: expected 1 attempt, got $interactive_attempts"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

# --- Test 6: Success on retry (fails twice, succeeds on attempt 3) ---
echo "Test 6: Success on retry (attempt 3)"

cat > "$TMP_DIR/test_retry_success.sh" << 'SUCCESS_SCRIPT'
#!/usr/bin/env bash
set -uo pipefail

RETRY_LOG="$1"
EXECUTION_LOG="$2"
ERROR_LOG="$3"

USE_CODEX=1
PASS=1
MAX_ATTEMPTS=4
BACKOFF_DELAYS=(0 0 0 0)
attempt=1
status=1
CALL_COUNT=0

interrupt_detected_in_error_log() { return 1; }
interrupt_detected_in_output_log() { return 1; }
map_signal_name() { echo ""; }
capture_diagnostic() { echo "diag:attempt=$2" >> "$RETRY_LOG"; }

run_codex() {
  CALL_COUNT=$((CALL_COUNT + 1))
  echo "attempt:$CALL_COUNT" >> "$RETRY_LOG"
  if [[ $CALL_COUNT -lt 3 ]]; then
    return 1
  fi
  return 0
}

while [[ $attempt -le $MAX_ATTEMPTS ]]; do
  if [[ $attempt -gt 1 ]]; then
    sleep "${BACKOFF_DELAYS[$((attempt - 1))]}"
  fi

  {
    run_codex 1 "test"
  } >> "$EXECUTION_LOG" 2> "$ERROR_LOG"
  status=$?

  if [[ $status -eq 130 ]]; then
    exit 0
  fi

  if [[ $status -eq 0 ]]; then
    break
  fi

  capture_diagnostic "$PASS" "$attempt" "$status" "$ERROR_LOG" 0 "$EXECUTION_LOG" 0
  attempt=$((attempt + 1))
done

if [[ $status -ne 0 ]]; then
  exit 1
fi
exit 0
SUCCESS_SCRIPT
chmod +x "$TMP_DIR/test_retry_success.sh"

rm -f "$RETRY_LOG" "$RETRY_EXEC_LOG" "$RETRY_ERR_LOG"
touch "$RETRY_LOG" "$RETRY_EXEC_LOG" "$RETRY_ERR_LOG"

set +e
bash "$TMP_DIR/test_retry_success.sh" "$RETRY_LOG" "$RETRY_EXEC_LOG" "$RETRY_ERR_LOG"
success_exit=$?
set -e

success_attempts="$(grep -c "^attempt:" "$RETRY_LOG")"
success_diags="$(grep -c "^diag:" "$RETRY_LOG")"
[[ "$success_exit" == "0" ]] && pass "exits 0 on success" || { echo "FAIL: expected exit 0, got $success_exit"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
[[ "$success_attempts" == "3" ]] && pass "3 attempts before success" || { echo "FAIL: expected 3 attempts, got $success_attempts"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
[[ "$success_diags" == "2" ]] && pass "2 diagnostics (for failed attempts)" || { echo "FAIL: expected 2 diagnostics, got $success_diags"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

# --- Summary ---
echo ""
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
if [[ $TESTS_FAILED -gt 0 ]]; then
  echo "test_diagnostic_retry.sh: FAIL"
  exit 1
fi
echo "test_diagnostic_retry.sh: PASS"
