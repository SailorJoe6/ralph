#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
START_BIN="$RALPH_DIR/start"

if [[ ! -x "$START_BIN" ]]; then
  echo "Expected executable not found: $START_BIN" >&2
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

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local label="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "Assertion failed: $label" >&2
    echo "Did not expect to find: $needle" >&2
    echo "Actual output:" >&2
    echo "$haystack" >&2
    exit 1
  fi
}

RUN_STATUS=0
RUN_STDOUT=""
RUN_STDERR=""

run_start() {
  local cwd="$1"
  local home_dir="$2"
  local stdout_file=""
  local stderr_file=""
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  set +e
  (
    cd "$cwd"
    HOME="$home_dir" PATH="$FAKE_BIN:$PATH" "$START_BIN"
  ) >"$stdout_file" 2>"$stderr_file"
  RUN_STATUS=$?
  set -e
  RUN_STDOUT="$(cat "$stdout_file")"
  RUN_STDERR="$(cat "$stderr_file")"
  rm -f "$stdout_file" "$stderr_file"
}

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

FAKE_BIN="$TMP_ROOT/fake-bin"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/claude" <<'EOF'
#!/usr/bin/env bash
echo "fake claude failure" >&2
exit 7
EOF
chmod +x "$FAKE_BIN/claude"

# Case 1: valid runtime root proceeds beyond preflight
VALID_HOME="$TMP_ROOT/home-valid"
VALID_ROOT="$TMP_ROOT/valid-project"
mkdir -p "$VALID_HOME" "$VALID_ROOT/.ralph/prompts"
cat > "$VALID_ROOT/.ralph/prompts/design.md" <<'EOF'
Design prompt
EOF

run_start "$VALID_ROOT" "$VALID_HOME"
[[ "$RUN_STATUS" == "1" ]] || { echo "Expected valid-root run to exit 1 after fake claude failure" >&2; exit 1; }
assert_contains "$RUN_STDOUT$RUN_STDERR" "Claude exited with status 7" "valid root reaches runtime execution"
assert_not_contains "$RUN_STDERR" "Ralph runtime requires a V2 project root" "valid root should not fail preflight"

# Case 2: legacy ./ralph detected in cwd
LEGACY_HOME="$TMP_ROOT/home-legacy"
LEGACY_ROOT="$TMP_ROOT/legacy-project"
mkdir -p "$LEGACY_HOME" "$LEGACY_ROOT/ralph"

run_start "$LEGACY_ROOT" "$LEGACY_HOME"
[[ "$RUN_STATUS" == "1" ]] || { echo "Expected legacy-root run to exit 1" >&2; exit 1; }
assert_contains "$RUN_STDERR" "legacy V1 Ralph folder detected" "legacy detection message"
assert_contains "$RUN_STDERR" "./ralph/start" "legacy guidance includes v1 command"
assert_contains "$RUN_STDERR" "ralph upgrade" "legacy guidance includes upgrade command"

# Case 3: no .ralph anywhere
NO_ROOT_HOME="$TMP_ROOT/home-no-root"
NO_ROOT_CWD="$TMP_ROOT/no-root/project"
mkdir -p "$NO_ROOT_HOME" "$NO_ROOT_CWD"

run_start "$NO_ROOT_CWD" "$NO_ROOT_HOME"
[[ "$RUN_STATUS" == "1" ]] || { echo "Expected no-root run to exit 1" >&2; exit 1; }
assert_contains "$RUN_STDERR" "No '.ralph' directory was found in the current directory or any parent directories." "message1 no-root detail"
assert_contains "$RUN_STDERR" "ralph init --project <path>" "message1 includes init --project guidance"

# Case 4: only ~/.ralph exists
HOME_ONLY_HOME="$TMP_ROOT/home-only"
HOME_ONLY_CWD="$TMP_ROOT/home-only-work/project"
mkdir -p "$HOME_ONLY_HOME/.ralph" "$HOME_ONLY_CWD"

run_start "$HOME_ONLY_CWD" "$HOME_ONLY_HOME"
[[ "$RUN_STATUS" == "1" ]] || { echo "Expected home-only run to exit 1" >&2; exit 1; }
assert_contains "$RUN_STDERR" "Only user-level Ralph config was found at:" "message2 home-only detail"
assert_contains "$RUN_STDERR" "$HOME_ONLY_HOME/.ralph" "message2 prints home .ralph path"
assert_contains "$RUN_STDERR" "cannot be used as a project root" "message2 explains home restriction"

# Case 5: ancestor .ralph above cwd
ANCESTOR_HOME="$TMP_ROOT/home-ancestor"
ANCESTOR_ROOT="$TMP_ROOT/ancestor-project"
ANCESTOR_CWD="$ANCESTOR_ROOT/sub/dir"
mkdir -p "$ANCESTOR_HOME" "$ANCESTOR_ROOT/.ralph" "$ANCESTOR_CWD"

run_start "$ANCESTOR_CWD" "$ANCESTOR_HOME"
[[ "$RUN_STATUS" == "1" ]] || { echo "Expected ancestor-root run to exit 1" >&2; exit 1; }
assert_contains "$RUN_STDERR" "Ralph must be run from the project root directory." "message3 root requirement"
assert_contains "$RUN_STDERR" "$ANCESTOR_CWD" "message3 includes current directory"
assert_contains "$RUN_STDERR" "$ANCESTOR_ROOT" "message3 includes detected root path"

echo "test_runtime_root_enforcement.sh: PASS"
