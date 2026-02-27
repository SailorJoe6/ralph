#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RALPH_BIN="$RALPH_DIR/ralph"

if [[ ! -x "$RALPH_BIN" ]]; then
  echo "Expected executable not found: $RALPH_BIN" >&2
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

assert_symlink_target() {
  local path="$1"
  local expected="$2"
  local label="$3"
  local actual=""

  if [[ ! -L "$path" ]]; then
    echo "Assertion failed: $label" >&2
    echo "Expected symlink, but got: $path" >&2
    exit 1
  fi

  actual="$(readlink "$path")"
  if [[ "$actual" != "$expected" ]]; then
    echo "Assertion failed: $label" >&2
    echo "  expected symlink target: $expected" >&2
    echo "  actual symlink target:   $actual" >&2
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

# Case 1: clean legacy migration with rewrites from defaults and full deletion.
PROJECT1="$TMP_ROOT/project-clean"
mkdir -p \
  "$PROJECT1/ralph/prompts" \
  "$PROJECT1/ralph/plans/archive" \
  "$PROJECT1/ralph/plans/blocked" \
  "$PROJECT1/ralph/plans/future" \
  "$PROJECT1/ralph/logs"
printf 'design prompt\n' > "$PROJECT1/ralph/prompts/design.md"
printf 'spec\n' > "$PROJECT1/ralph/plans/SPECIFICATION.md"
printf 'plan\n' > "$PROJECT1/ralph/plans/EXECUTION_PLAN.md"
printf 'archive plan\n' > "$PROJECT1/ralph/plans/archive/old.md"
printf 'blocked\n' > "$PROJECT1/ralph/plans/blocked/SPECIFICATION.md"
printf 'future plan\n' > "$PROJECT1/ralph/plans/future/idea.md"
printf 'error log\n' > "$PROJECT1/ralph/logs/ERROR_LOG.md"
printf 'output log\n' > "$PROJECT1/ralph/logs/OUTPUT_LOG.md"

run_cmd "$RALPH_BIN" upgrade --project "$PROJECT1"
assert_eq "$RUN_STATUS" "0" "clean migration exit status"
assert_exists "$PROJECT1/.ralph/.env" "migrated .env created"
assert_exists "$PROJECT1/.ralph/.env.example" "migrated .env.example copied"
assert_exists "$PROJECT1/.ralph/prompts/design.md" "design prompt migrated"
assert_exists "$PROJECT1/.ralph/plans/SPECIFICATION.md" "spec migrated"
assert_exists "$PROJECT1/.ralph/plans/EXECUTION_PLAN.md" "plan migrated"
assert_exists "$PROJECT1/.ralph/plans/archive/old.md" "archive plans migrated recursively"
assert_exists "$PROJECT1/.ralph/plans/blocked/SPECIFICATION.md" "blocked spec migrated"
assert_exists "$PROJECT1/.ralph/plans/future/idea.md" "future plans migrated recursively"
assert_exists "$PROJECT1/.ralph/logs/ERROR_LOG.md" "error log migrated"
assert_exists "$PROJECT1/.ralph/logs/OUTPUT_LOG.md" "output log migrated"
assert_not_exists "$PROJECT1/ralph" "legacy directory removed when empty"
assert_contains "$(cat "$PROJECT1/.ralph/.env")" "SPECIFICATION=.ralph/plans/SPECIFICATION.md" "default specification rewrite persisted"
assert_contains "$RUN_STDERR" "Rewriting SPECIFICATION" "rewrite warning emitted"

# Case 2: precondition failure when legacy folder is missing.
PROJECT2="$TMP_ROOT/project-no-legacy"
mkdir -p "$PROJECT2"
run_cmd "$RALPH_BIN" upgrade --project "$PROJECT2"
assert_eq "$RUN_STATUS" "1" "missing legacy precondition exit status"
assert_contains "$RUN_STDERR" "legacy V1 Ralph folder not found" "missing legacy error"

# Case 3: precondition failure when .ralph already exists.
PROJECT3="$TMP_ROOT/project-existing-v2"
mkdir -p "$PROJECT3/ralph" "$PROJECT3/.ralph"
run_cmd "$RALPH_BIN" upgrade --project "$PROJECT3"
assert_eq "$RUN_STATUS" "1" "existing .ralph precondition exit status"
assert_contains "$RUN_STDERR" "target V2 folder already exists" "existing .ralph error"

# Case 4: explicit legacy env paths rewrite to V2 defaults and preserve unrelated vars.
PROJECT4="$TMP_ROOT/project-rewrite"
mkdir -p "$PROJECT4/ralph/custom/logs" "$PROJECT4/ralph/custom"
cat > "$PROJECT4/ralph/.env" <<'EOF_ENV'
SPECIFICATION=ralph/custom/spec.md
EXECUTION_PLAN=ralph/custom/plan.md
LOG_DIR=ralph/custom/logs
ERROR_LOG=ralph/custom/logs/custom-error.md
OUTPUT_LOG=ralph/custom/logs/custom-output.md
CALLBACK=./scripts/check.sh
UNRELATED_FLAG=keep-me
EOF_ENV
printf 'spec data\n' > "$PROJECT4/ralph/custom/spec.md"
printf 'plan data\n' > "$PROJECT4/ralph/custom/plan.md"
printf 'custom err\n' > "$PROJECT4/ralph/custom/logs/custom-error.md"
printf 'custom out\n' > "$PROJECT4/ralph/custom/logs/custom-output.md"

run_cmd "$RALPH_BIN" upgrade --project "$PROJECT4"
assert_eq "$RUN_STATUS" "0" "explicit rewrite migration exit status"
assert_contains "$RUN_STDERR" "Rewriting SPECIFICATION" "explicit specification rewrite warning"
assert_contains "$RUN_STDERR" "Rewriting EXECUTION_PLAN" "explicit execution plan rewrite warning"
assert_contains "$RUN_STDERR" "Rewriting LOG_DIR" "explicit log dir rewrite warning"
assert_contains "$(cat "$PROJECT4/.ralph/.env")" "UNRELATED_FLAG=keep-me" "unrelated env setting preserved"
assert_contains "$(cat "$PROJECT4/.ralph/.env")" "CALLBACK=./scripts/check.sh" "callback setting preserved"
assert_exists "$PROJECT4/.ralph/plans/SPECIFICATION.md" "custom spec moved to default v2 path"
assert_exists "$PROJECT4/.ralph/plans/EXECUTION_PLAN.md" "custom plan moved to default v2 path"
assert_exists "$PROJECT4/.ralph/logs/ERROR_LOG.md" "custom error log moved to default v2 path"
assert_exists "$PROJECT4/.ralph/logs/OUTPUT_LOG.md" "custom output log moved to default v2 path"

# Case 5: unknown legacy content without a git repo fails with explicit error.
PROJECT5="$TMP_ROOT/project-unknown"
mkdir -p "$PROJECT5/ralph/prompts"
printf 'design prompt\n' > "$PROJECT5/ralph/prompts/design.md"
printf 'keep legacy file\n' > "$PROJECT5/ralph/notes.txt"
run_cmd "$RALPH_BIN" upgrade --project "$PROJECT5"
assert_eq "$RUN_STATUS" "1" "unknown content without git repo exit status"
assert_exists "$PROJECT5/.ralph/prompts/design.md" "known prompt still migrated before cleanup error"
assert_exists "$PROJECT5/ralph" "legacy directory retained when cleanup safety check fails"
assert_exists "$PROJECT5/ralph/notes.txt" "unknown legacy content preserved"
assert_contains "$RUN_STDERR" "Cannot remove legacy directory" "unknown-content cleanup error emitted"
assert_contains "$RUN_STDERR" "legacy folder is not a git repository" "non-git cleanup reason emitted"

# Case 6: missing optional known files still succeeds.
PROJECT6="$TMP_ROOT/project-minimal"
mkdir -p "$PROJECT6/ralph"
run_cmd "$RALPH_BIN" upgrade --project "$PROJECT6"
assert_eq "$RUN_STATUS" "0" "minimal migration exit status"
assert_exists "$PROJECT6/.ralph" "v2 root created for minimal migration"
assert_not_exists "$PROJECT6/ralph" "empty legacy directory removed"

# Case 7: --project resolves relative paths.
PROJECT7="$TMP_ROOT/relative-target"
mkdir -p "$PROJECT7/ralph"
ORIG_PWD="$(pwd)"
cd "$TMP_ROOT"
run_cmd "$RALPH_BIN" upgrade --project "./relative-target/./..//relative-target"
cd "$ORIG_PWD"
assert_eq "$RUN_STATUS" "0" "relative --project migration exit status"
assert_exists "$PROJECT7/.ralph" "relative --project migrated target"

# Case 8: --stealth updates git exclude for created .ralph.
PROJECT8="$TMP_ROOT/project-stealth"
mkdir -p "$PROJECT8/ralph"
(
  cd "$PROJECT8"
  git init -q
)
run_cmd "$RALPH_BIN" upgrade --project "$PROJECT8" --stealth
assert_eq "$RUN_STATUS" "0" "stealth migration exit status"
assert_contains "$(cat "$PROJECT8/.git/info/exclude")" ".ralph/" "stealth exclude contains .ralph"

# Case 9: known placeholder files should not block legacy directory removal.
PROJECT9="$TMP_ROOT/project-placeholder-cleanup"
mkdir -p \
  "$PROJECT9/ralph/prompts" \
  "$PROJECT9/ralph/plans/archive" \
  "$PROJECT9/ralph/plans/blocked" \
  "$PROJECT9/ralph/plans/future" \
  "$PROJECT9/ralph/logs"
printf 'design prompt\n' > "$PROJECT9/ralph/prompts/design.md"
printf 'placeholder\n' > "$PROJECT9/ralph/plans/.keep"
printf 'placeholder\n' > "$PROJECT9/ralph/plans/archive/.keep"
printf 'placeholder\n' > "$PROJECT9/ralph/plans/blocked/.keep"
printf 'placeholder\n' > "$PROJECT9/ralph/plans/future/.keep"
printf 'placeholder\n' > "$PROJECT9/ralph/logs/.keep"

run_cmd "$RALPH_BIN" upgrade --project "$PROJECT9"
assert_eq "$RUN_STATUS" "0" "placeholder cleanup migration exit status"
assert_exists "$PROJECT9/.ralph/prompts/design.md" "placeholder cleanup still migrated prompts"
assert_not_exists "$PROJECT9/ralph" "legacy directory removed when only placeholder content remained"
assert_not_contains "$RUN_STDERR" "Legacy directory retained" "placeholder files are not treated as unknown legacy content"

# Case 10: prompt examples are not migrated; clean legacy git repo allows full removal.
PROJECT10="$TMP_ROOT/project-prompt-filter"
mkdir -p "$PROJECT10/ralph/prompts"
printf 'active prompt\n' > "$PROJECT10/ralph/prompts/design.md"
printf 'example prompt\n' > "$PROJECT10/ralph/prompts/design.example.md"
printf 'tracked metadata\n' > "$PROJECT10/ralph/README.md"
cat > "$PROJECT10/ralph/.gitignore" <<'EOF_GITIGNORE'
prompts/design.md
plans/
logs/
.env
.env.example
EOF_GITIGNORE
(
  cd "$PROJECT10/ralph"
  git init -q
  git add README.md .gitignore prompts/design.example.md
  git -c user.name='Ralph Test' -c user.email='ralph-test@example.com' commit -q -m 'seed legacy repo'
)
run_cmd "$RALPH_BIN" upgrade --project "$PROJECT10"
assert_eq "$RUN_STATUS" "0" "clean legacy git repo deletion exit status"
assert_exists "$PROJECT10/.ralph/prompts/design.md" "active prompt migrated"
assert_not_exists "$PROJECT10/.ralph/prompts/design.example.md" "example prompt not migrated"
assert_not_exists "$PROJECT10/ralph" "legacy directory removed when clean git repo had residual content"

# Case 11: dirty legacy git repo blocks full removal and returns error.
PROJECT11="$TMP_ROOT/project-dirty-git"
mkdir -p "$PROJECT11/ralph/prompts"
printf 'active prompt\n' > "$PROJECT11/ralph/prompts/design.md"
printf 'tracked metadata\n' > "$PROJECT11/ralph/README.md"
cat > "$PROJECT11/ralph/.gitignore" <<'EOF_GITIGNORE2'
prompts/design.md
plans/
logs/
.env
.env.example
EOF_GITIGNORE2
(
  cd "$PROJECT11/ralph"
  git init -q
  git add README.md .gitignore
  git -c user.name='Ralph Test' -c user.email='ralph-test@example.com' commit -q -m 'seed dirty legacy repo'
  printf 'local edit\n' >> README.md
)
run_cmd "$RALPH_BIN" upgrade --project "$PROJECT11"
assert_eq "$RUN_STATUS" "1" "dirty legacy git repo cleanup failure exit status"
assert_exists "$PROJECT11/ralph" "legacy directory retained when git repo is dirty"
assert_contains "$RUN_STDERR" "legacy git repository is not clean" "dirty git cleanup reason emitted"

# Case 12: existing .claude/.codex command symlinks to legacy prompts are rewritten.
PROJECT12="$TMP_ROOT/project-symlink-rewrite"
mkdir -p \
  "$PROJECT12/ralph/prompts" \
  "$PROJECT12/.claude/commands" \
  "$PROJECT12/.codex/commands"
printf 'design prompt\n' > "$PROJECT12/ralph/prompts/design.md"
printf 'plan prompt\n' > "$PROJECT12/ralph/prompts/plan.md"
ln -s "../../ralph/prompts/design.md" "$PROJECT12/.claude/commands/design.md"
ln -s "../../ralph/prompts/plan.md" "$PROJECT12/.codex/commands/plan.md"

run_cmd "$RALPH_BIN" upgrade --project "$PROJECT12"
assert_eq "$RUN_STATUS" "0" "legacy prompt symlink rewrite exit status"
assert_not_exists "$PROJECT12/ralph" "legacy directory removed after symlink rewrite migration"
assert_symlink_target "$PROJECT12/.claude/commands/design.md" "../../.ralph/prompts/design.md" "claude design symlink rewritten"
assert_symlink_target "$PROJECT12/.codex/commands/plan.md" "../../.ralph/prompts/plan.md" "codex plan symlink rewritten"

echo "test_upgrade_v2.sh: PASS"
