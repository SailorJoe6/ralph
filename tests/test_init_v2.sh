#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RALPH_BIN="$RALPH_DIR/ralph"

if [[ ! -x "$RALPH_BIN" ]]; then
  echo "Expected executable not found: $RALPH_BIN" >&2
  exit 1
fi

assert_exists() {
  local path="$1"
  local label="$2"
  if [[ ! -e "$path" ]]; then
    echo "Assertion failed: $label" >&2
    echo "Missing path: $path" >&2
    exit 1
  fi
}

assert_dir() {
  local path="$1"
  local label="$2"
  if [[ ! -d "$path" ]]; then
    echo "Assertion failed: $label" >&2
    echo "Expected directory: $path" >&2
    exit 1
  fi
}

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

# Case 1: empty directory init creates V2 tree and default prompts.
PROJECT1="$TMP_ROOT/project-empty"
run_cmd "$RALPH_BIN" init --project "$PROJECT1"
assert_eq "$RUN_STATUS" "0" "init empty dir exit status"
assert_dir "$PROJECT1/.ralph" "init creates .ralph"
assert_dir "$PROJECT1/.ralph/prompts" "init creates prompts dir"
assert_dir "$PROJECT1/.ralph/plans" "init creates plans dir"
assert_dir "$PROJECT1/.ralph/logs" "init creates logs dir"
assert_file_equals "$RALPH_DIR/.env.example" "$PROJECT1/.ralph/.env.example" "init overwrites .env.example from bundled template"
assert_file_equals "$RALPH_DIR/prompts/execute.example.md" "$PROJECT1/.ralph/prompts/execute.md" "default execute template"
assert_file_equals "$RALPH_DIR/prompts/handoff.example.md" "$PROJECT1/.ralph/prompts/handoff.md" "default handoff template"
assert_file_equals "$RALPH_DIR/prompts/prepare.example.md" "$PROJECT1/.ralph/prompts/prepare.md" "default prepare template"

# Case 2: existing active prompt is preserved; .env.example is always overwritten.
PROJECT2="$TMP_ROOT/project-existing"
mkdir -p "$PROJECT2/.ralph/prompts"
printf 'KEEP PLAN CONTENT\n' > "$PROJECT2/.ralph/prompts/plan.md"
printf 'OLD ENV CONTENT\n' > "$PROJECT2/.ralph/.env.example"
run_cmd "$RALPH_BIN" init --project "$PROJECT2"
assert_eq "$RUN_STATUS" "0" "init existing dir exit status"
assert_eq "$(cat "$PROJECT2/.ralph/prompts/plan.md")" "KEEP PLAN CONTENT" "existing prompt preserved"
assert_file_equals "$RALPH_DIR/.env.example" "$PROJECT2/.ralph/.env.example" ".env.example overwritten"

# Case 3: --project relative missing path is created.
(
  cd "$TMP_ROOT"
  run_cmd "$RALPH_BIN" init --project "./nested/../project-created"
)
assert_eq "$RUN_STATUS" "0" "init --project missing path exit status"
assert_dir "$TMP_ROOT/project-created/.ralph" "init creates resolved --project root"

# Case 4: --beads runs bd init and uses beads prompt variants when available.
PROJECT3="$TMP_ROOT/project-beads"
FAKE_BIN="$TMP_ROOT/fake-bin"
BD_LOG="$TMP_ROOT/bd.log"
mkdir -p "$FAKE_BIN"
cat > "$FAKE_BIN/bd" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "init" ]]; then
  mkdir -p .beads
  printf 'bd init %s\n' "$(pwd)" >> "${BD_LOG:?missing BD_LOG}"
  exit 0
fi
echo "unexpected bd args: $*" >&2
exit 2
EOF
chmod +x "$FAKE_BIN/bd"

run_cmd env PATH="$FAKE_BIN:$PATH" BD_LOG="$BD_LOG" "$RALPH_BIN" init --project "$PROJECT3" --beads
assert_eq "$RUN_STATUS" "0" "init --beads exit status"
assert_dir "$PROJECT3/.beads" "beads init creates .beads"
assert_contains "$(cat "$BD_LOG")" "bd init $PROJECT3" "bd init invoked in project root"
assert_file_equals "$RALPH_DIR/prompts/execute.example.beads.md" "$PROJECT3/.ralph/prompts/execute.md" "beads execute template"
assert_file_equals "$RALPH_DIR/prompts/handoff.example.beads.md" "$PROJECT3/.ralph/prompts/handoff.md" "beads handoff template"
assert_file_equals "$RALPH_DIR/prompts/prepare.example.beads.md" "$PROJECT3/.ralph/prompts/prepare.md" "beads prepare template"
assert_file_equals "$RALPH_DIR/prompts/blocked.example.md" "$PROJECT3/.ralph/prompts/blocked.md" "blocked fallback template"

# Re-run with existing .beads should remain successful and skip repeated bd init.
run_cmd env PATH="$FAKE_BIN:$PATH" BD_LOG="$BD_LOG" "$RALPH_BIN" init --project "$PROJECT3" --beads
assert_eq "$RUN_STATUS" "0" "re-run init --beads exit status"
assert_eq "$(wc -l < "$BD_LOG")" "1" "bd init not repeated when .beads already exists"

# Case 5: --stealth excludes only newly created folders and symlink setup targets .ralph prompts.
PROJECT4="$TMP_ROOT/project-stealth"
mkdir -p "$PROJECT4"
(
  cd "$PROJECT4"
  git init >/dev/null
)
run_cmd "$RALPH_BIN" init --project "$PROJECT4" --stealth --claude --codex
assert_eq "$RUN_STATUS" "0" "init --stealth exit status"
EXCLUDE_FILE="$PROJECT4/.git/info/exclude"
assert_exists "$EXCLUDE_FILE" "exclude file exists"
EXCLUDE_CONTENT="$(cat "$EXCLUDE_FILE")"
assert_contains "$EXCLUDE_CONTENT" ".ralph/" "exclude includes .ralph"
assert_contains "$EXCLUDE_CONTENT" ".claude/" "exclude includes .claude"
assert_contains "$EXCLUDE_CONTENT" ".codex/" "exclude includes .codex"
assert_not_contains "$EXCLUDE_CONTENT" ".beads/" "exclude omits .beads when not created"
assert_eq "$(readlink "$PROJECT4/.claude/commands/design.md")" "../../.ralph/prompts/design.md" "claude symlink target"
assert_eq "$(readlink "$PROJECT4/.codex/commands/prepare.md")" "../../.ralph/prompts/prepare.md" "codex symlink target"

# Re-run should not duplicate exclude entries.
run_cmd "$RALPH_BIN" init --project "$PROJECT4" --stealth --claude --codex
assert_eq "$RUN_STATUS" "0" "re-run init --stealth exit status"
assert_eq "$(grep -Fxc '.ralph/' "$EXCLUDE_FILE")" "1" "exclude .ralph not duplicated"
assert_eq "$(grep -Fxc '.claude/' "$EXCLUDE_FILE")" "1" "exclude .claude not duplicated"
assert_eq "$(grep -Fxc '.codex/' "$EXCLUDE_FILE")" "1" "exclude .codex not duplicated"

# Case 6: --stealth without git metadata warns and continues.
PROJECT5="$TMP_ROOT/project-no-git"
run_cmd "$RALPH_BIN" init --project "$PROJECT5" --stealth
assert_eq "$RUN_STATUS" "0" "init --stealth without git exits successfully"
assert_contains "$RUN_STDERR" "not inside a git work tree" "missing git metadata warning"

echo "test_init_v2.sh: PASS"
