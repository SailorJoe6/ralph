#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SCRIPT="$RALPH_DIR/install"

if [[ ! -x "$INSTALL_SCRIPT" ]]; then
  echo "Expected executable not found: $INSTALL_SCRIPT" >&2
  exit 1
fi

assert_eq() {
  local actual="$1"
  local expected="$2"
  local label="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "Assertion failed: $label" >&2
    echo "  expected: $expected" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi
}

assert_exists() {
  local path="$1"
  local label="$2"
  if [[ ! -e "$path" ]]; then
    echo "Assertion failed: $label" >&2
    echo "Missing path: $path" >&2
    exit 1
  fi
}

assert_not_exists() {
  local path="$1"
  local label="$2"
  if [[ -e "$path" ]]; then
    echo "Assertion failed: $label" >&2
    echo "Path should not exist: $path" >&2
    exit 1
  fi
}

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

assert_file_equals() {
  local left="$1"
  local right="$2"
  local label="$3"
  if ! cmp -s "$left" "$right"; then
    echo "Assertion failed: $label" >&2
    echo "Files differ:" >&2
    echo "  $left" >&2
    echo "  $right" >&2
    exit 1
  fi
}

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

RUN_STATUS=0
RUN_STDOUT=""
RUN_STDERR=""

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

HOME_DIR="$TMP_ROOT/home"
mkdir -p "$HOME_DIR"

# Case 1: fresh install into empty HOME creates wrapper/runtime/user template.
run_cmd env HOME="$HOME_DIR" "$INSTALL_SCRIPT"
assert_eq "$RUN_STATUS" "0" "fresh install exit status"
assert_exists "$HOME_DIR/.local/bin/ralph" "wrapper created"
assert_exists "$HOME_DIR/.local/share/ralph/ralph" "runtime command installed"
assert_exists "$HOME_DIR/.ralph/.env.example" "user env example installed"
assert_not_exists "$HOME_DIR/.ralph/.env" "user env not auto-created"
assert_file_equals "$RALPH_DIR/.env.example" "$HOME_DIR/.ralph/.env.example" "user env example overwritten from bundled template"
assert_contains "$RUN_STDOUT" "Ralph does not create ~/.ralph/.env automatically." "post-install guidance"

run_cmd env HOME="$HOME_DIR" PATH="$HOME_DIR/.local/bin:$PATH" "$HOME_DIR/.local/bin/ralph" --help
assert_eq "$RUN_STATUS" "0" "installed wrapper help exit status"
assert_contains "$RUN_STDOUT" "Usage: ralph [OPTIONS]" "installed wrapper executes runtime"

# Case 2: reinstall overwrites wrapper/runtime/.env.example and preserves ~/.ralph/.env.
printf 'KEEP=1\n' > "$HOME_DIR/.ralph/.env"
printf 'STALE\n' > "$HOME_DIR/.local/share/ralph/stale.txt"
cat > "$HOME_DIR/.local/share/ralph/ralph" <<'EOF_BROKEN_RUNTIME'
#!/usr/bin/env bash
echo BROKEN RUNTIME
EOF_BROKEN_RUNTIME
chmod +x "$HOME_DIR/.local/share/ralph/ralph"
cat > "$HOME_DIR/.local/bin/ralph" <<'EOF_BROKEN_WRAPPER'
#!/usr/bin/env bash
echo BROKEN WRAPPER
EOF_BROKEN_WRAPPER
chmod +x "$HOME_DIR/.local/bin/ralph"
printf 'OLD TEMPLATE\n' > "$HOME_DIR/.ralph/.env.example"

run_cmd env HOME="$HOME_DIR" "$INSTALL_SCRIPT"
assert_eq "$RUN_STATUS" "0" "reinstall exit status"
assert_not_exists "$HOME_DIR/.local/share/ralph/stale.txt" "stale runtime file removed on reinstall"
assert_file_equals "$RALPH_DIR/.env.example" "$HOME_DIR/.ralph/.env.example" "env example refreshed on reinstall"
assert_eq "$(cat "$HOME_DIR/.ralph/.env")" "KEEP=1" "existing user env preserved"
assert_contains "$(cat "$HOME_DIR/.local/bin/ralph")" "exec $HOME_DIR/.local/share/ralph/ralph" "wrapper rewritten to installed runtime"
assert_file_equals "$RALPH_DIR/ralph" "$HOME_DIR/.local/share/ralph/ralph" "runtime entrypoint refreshed"

run_cmd env HOME="$HOME_DIR" PATH="$HOME_DIR/.local/bin:$PATH" "$HOME_DIR/.local/bin/ralph" --help
assert_eq "$RUN_STATUS" "0" "wrapper works after reinstall"
assert_contains "$RUN_STDOUT" "Usage: ralph [OPTIONS]" "reinstalled wrapper executes runtime"

# Case 3: running install from installed runtime directory is idempotent.
run_cmd env HOME="$HOME_DIR" "$HOME_DIR/.local/share/ralph/install"
assert_eq "$RUN_STATUS" "0" "in-place install exit status"
assert_contains "$RUN_STDOUT" "Runtime already present at install location" "in-place install messaging"
assert_eq "$(cat "$HOME_DIR/.ralph/.env")" "KEEP=1" "existing user env preserved during in-place install"

echo "test_install_v2.sh: PASS"
