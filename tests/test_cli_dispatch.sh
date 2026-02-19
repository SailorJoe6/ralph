#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_BIN="$(cd "$SCRIPT_DIR/.." && pwd)/ralph"

if [[ ! -x "$RALPH_BIN" ]]; then
  echo "Expected executable not found: $RALPH_BIN" >&2
  exit 1
fi

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "Assertion failed: $label" >&2
    echo "Expected to find: $needle" >&2
    echo "Actual output:" >&2
    echo "$haystack" >&2
    exit 1
  fi
}

RUN_STATUS=0
RUN_STDOUT=""
RUN_STDERR=""

run_cmd() {
  local stdout_file
  local stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  set +e
  "$@" >"$stdout_file" 2>"$stderr_file"
  RUN_STATUS=$?
  set -e
  RUN_STDOUT="$(cat "$stdout_file")"
  RUN_STDERR="$(cat "$stderr_file")"
  rm -f "$stdout_file" "$stderr_file"
}

run_cmd "$RALPH_BIN" --help
[[ "$RUN_STATUS" == "0" ]] || { echo "Expected ralph --help exit 0" >&2; exit 1; }
assert_contains "$RUN_STDOUT" "Usage: ralph [OPTIONS]" "runtime help usage"
assert_contains "$RUN_STDOUT" "Subcommands:" "runtime help subcommands"

run_cmd "$RALPH_BIN" start --help
[[ "$RUN_STATUS" == "0" ]] || { echo "Expected ralph start --help exit 0" >&2; exit 1; }
assert_contains "$RUN_STDOUT" "Reminder: 'ralph' is the default runtime command" "start alias reminder"
assert_contains "$RUN_STDOUT" "Usage: ralph [OPTIONS]" "start alias runtime help"

run_cmd "$RALPH_BIN" init --help
[[ "$RUN_STATUS" == "0" ]] || { echo "Expected ralph init --help exit 0" >&2; exit 1; }
assert_contains "$RUN_STDOUT" "Usage: ralph init [OPTIONS]" "init help usage"
assert_contains "$RUN_STDOUT" "--project <path>" "init help project flag"
assert_contains "$RUN_STDOUT" "--stealth" "init help stealth flag"

run_cmd "$RALPH_BIN" upgrade --help
[[ "$RUN_STATUS" == "0" ]] || { echo "Expected ralph upgrade --help exit 0" >&2; exit 1; }
assert_contains "$RUN_STDOUT" "Usage: ralph upgrade [OPTIONS]" "upgrade help usage"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
run_cmd "$RALPH_BIN" upgrade --project "$TMP_ROOT"
[[ "$RUN_STATUS" == "1" ]] || { echo "Expected ralph upgrade precondition failure exit 1" >&2; exit 1; }
assert_contains "$RUN_STDERR" "legacy V1 Ralph folder not found" "upgrade precondition error"

run_cmd "$RALPH_BIN" start --definitely-invalid
[[ "$RUN_STATUS" == "2" ]] || { echo "Expected invalid start option to exit 2" >&2; exit 1; }
assert_contains "$RUN_STDERR" "Reminder: 'ralph' is the default runtime command" "alias reminder on start invocation"
assert_contains "$RUN_STDOUT$RUN_STDERR" "Unknown option: --definitely-invalid" "start unknown option passthrough"

echo "test_cli_dispatch.sh: PASS"
