#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
START_BIN="$RALPH_DIR/start"

if [[ ! -x "$START_BIN" ]]; then
  echo "Expected executable not found: $START_BIN" >&2
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
  local path_prefix="$3"
  shift 3

  local stdout_file
  local stderr_file
  local path_value

  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  path_value="$PATH"
  if [[ -n "$path_prefix" ]]; then
    path_value="$path_prefix:$PATH"
  fi

  set +e
  (
    cd "$cwd"
    HOME="$home_dir" PATH="$path_value" "$@"
  ) >"$stdout_file" 2>"$stderr_file"
  RUN_STATUS=$?
  set -e
  RUN_STDOUT="$(cat "$stdout_file")"
  RUN_STDERR="$(cat "$stderr_file")"
  rm -f "$stdout_file" "$stderr_file"
}

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

# Case 1: default no-docs flow uses prepare prompt.
HOME1="$TMP_ROOT/home-default-prepare"
PROJECT1="$TMP_ROOT/project-default-prepare"
FAKE_BIN1="$TMP_ROOT/fake-bin-default-prepare"
TOOL_LOG1="$TMP_ROOT/default-prepare.log"
mkdir -p "$HOME1/.ralph" "$PROJECT1/.ralph/prompts" "$FAKE_BIN1"
cat > "$FAKE_BIN1/claude" <<'EOF_FAKE_CLAUDE_DEFAULT_PREPARE'
#!/usr/bin/env bash
set -euo pipefail
: "${TOOL_LOG:?}"
printf 'claude:' >> "$TOOL_LOG"
for arg in "$@"; do
  printf '[%s]' "$arg" >> "$TOOL_LOG"
done
printf '\n' >> "$TOOL_LOG"
exit 7
EOF_FAKE_CLAUDE_DEFAULT_PREPARE
cat > "$FAKE_BIN1/codex" <<'EOF_FAKE_CODEX_DEFAULT_PREPARE'
#!/usr/bin/env bash
set -euo pipefail
: "${TOOL_LOG:?}"
printf 'codex:' >> "$TOOL_LOG"
for arg in "$@"; do
  printf '[%s]' "$arg" >> "$TOOL_LOG"
done
printf '\n' >> "$TOOL_LOG"
exit 7
EOF_FAKE_CODEX_DEFAULT_PREPARE
chmod +x "$FAKE_BIN1/claude" "$FAKE_BIN1/codex"
cat > "$PROJECT1/.ralph/prompts/prepare.md" <<'EOF_PREPARE_WITH_FRONTMATTER'
---
name: prepare
description: test frontmatter
---
PREPARE_PROMPT_TEXT
EOF_PREPARE_WITH_FRONTMATTER

rm -f "$TOOL_LOG1"
run_start "$PROJECT1" "$HOME1" "$FAKE_BIN1" env TOOL_LOG="$TOOL_LOG1" "$START_BIN"
assert_eq "$RUN_STATUS" "1" "default prepare Claude exit status"
DEFAULT_PREPARE_CLAUDE="$(cat "$TOOL_LOG1")"
assert_contains "$DEFAULT_PREPARE_CLAUDE" "claude:" "default flow uses Claude by default"
assert_contains "$DEFAULT_PREPARE_CLAUDE" "[PREPARE_PROMPT_TEXT]" "default flow uses prepare prompt for Claude"
assert_not_contains "$DEFAULT_PREPARE_CLAUDE" "[name: prepare]" "default flow strips prepare frontmatter for Claude"

cat > "$HOME1/.ralph/.env" <<'EOF_HOME_DEFAULT_PREPARE'
USECODEX=1
EOF_HOME_DEFAULT_PREPARE

rm -f "$TOOL_LOG1"
run_start "$PROJECT1" "$HOME1" "$FAKE_BIN1" env TOOL_LOG="$TOOL_LOG1" "$START_BIN"
assert_eq "$RUN_STATUS" "1" "default prepare Codex exit status"
DEFAULT_PREPARE_CODEX="$(cat "$TOOL_LOG1")"
assert_contains "$DEFAULT_PREPARE_CODEX" "codex:" "default flow uses Codex when configured"
assert_contains "$DEFAULT_PREPARE_CODEX" "[PREPARE_PROMPT_TEXT]" "default flow uses prepare prompt for Codex"
assert_not_contains "$DEFAULT_PREPARE_CODEX" "[name: prepare]" "default flow strips prepare frontmatter for Codex"

# Case 1b: blocked docs nested under blocked/ still trigger blocked prompt.
HOME1B="$TMP_ROOT/home-blocked-nested"
PROJECT1B="$TMP_ROOT/project-blocked-nested"
FAKE_BIN1B="$TMP_ROOT/fake-bin-blocked-nested"
TOOL_LOG1B="$TMP_ROOT/blocked-nested.log"
mkdir -p "$HOME1B/.ralph" "$PROJECT1B/.ralph/prompts" "$PROJECT1B/.ralph/plans/blocked/nested" "$FAKE_BIN1B"
cat > "$FAKE_BIN1B/claude" <<'EOF_FAKE_CLAUDE_BLOCKED_NESTED'
#!/usr/bin/env bash
set -euo pipefail
: "${TOOL_LOG:?}"
printf 'claude:' >> "$TOOL_LOG"
for arg in "$@"; do
  printf '[%s]' "$arg" >> "$TOOL_LOG"
done
printf '\n' >> "$TOOL_LOG"
exit 7
EOF_FAKE_CLAUDE_BLOCKED_NESTED
chmod +x "$FAKE_BIN1B/claude"
cat > "$PROJECT1B/.ralph/prompts/blocked.md" <<'EOF_BLOCKED_WITH_FRONTMATTER'
---
name: blocked
description: test frontmatter
---
BLOCKED_PROMPT_TEXT
EOF_BLOCKED_WITH_FRONTMATTER
printf 'blocked spec\n' > "$PROJECT1B/.ralph/plans/blocked/nested/SPECIFICATION.md"

rm -f "$TOOL_LOG1B"
run_start "$PROJECT1B" "$HOME1B" "$FAKE_BIN1B" env TOOL_LOG="$TOOL_LOG1B" "$START_BIN"
assert_eq "$RUN_STATUS" "1" "blocked nested Claude exit status"
BLOCKED_NESTED_CLAUDE="$(cat "$TOOL_LOG1B")"
assert_contains "$BLOCKED_NESTED_CLAUDE" "claude:" "blocked nested uses Claude by default"
assert_contains "$BLOCKED_NESTED_CLAUDE" "[BLOCKED_PROMPT_TEXT]" "blocked nested uses blocked prompt"
assert_not_contains "$BLOCKED_NESTED_CLAUDE" "[name: blocked]" "blocked flow strips frontmatter"

# Case 2: missing active prompt shows template-copy guidance.
HOME1="$TMP_ROOT/home-missing-prompt"
PROJECT1="$TMP_ROOT/project-missing-prompt"
mkdir -p "$HOME1" "$PROJECT1/.ralph/prompts"

run_start "$PROJECT1" "$HOME1" "" "$START_BIN"
assert_eq "$RUN_STATUS" "1" "missing prompt exit status"
assert_contains "$RUN_STDOUT$RUN_STDERR" "Prompt file not found: $PROJECT1/.ralph/prompts/prepare.md" "missing prompt path"
assert_contains "$RUN_STDOUT$RUN_STDERR" "/prompts/prepare.example.md" "missing prompt prepare template guidance"
assert_contains "$RUN_STDOUT$RUN_STDERR" "$PROJECT1/.ralph/prompts/prepare.md" "missing prompt destination guidance"

# Case 3: unattended execute mode writes logs to .ralph/logs.
HOME2="$TMP_ROOT/home-unattended"
PROJECT2="$TMP_ROOT/project-unattended"
FAKE_BIN2="$TMP_ROOT/fake-bin-unattended"
mkdir -p "$HOME2" "$PROJECT2/.ralph/prompts" "$PROJECT2/.ralph/plans" "$FAKE_BIN2"
cat > "$FAKE_BIN2/claude" <<'EOF_FAKE_CLAUDE_UNATTENDED'
#!/usr/bin/env bash
echo "fake-claude-stdout"
echo "fake-claude-stderr" >&2
exit 7
EOF_FAKE_CLAUDE_UNATTENDED
chmod +x "$FAKE_BIN2/claude"
printf 'execute prompt\n' > "$PROJECT2/.ralph/prompts/execute.md"
printf 'handoff prompt\n' > "$PROJECT2/.ralph/prompts/handoff.md"
printf 'spec\n' > "$PROJECT2/.ralph/plans/SPECIFICATION.md"
printf 'plan\n' > "$PROJECT2/.ralph/plans/EXECUTION_PLAN.md"

run_start "$PROJECT2" "$HOME2" "$FAKE_BIN2" "$START_BIN" --unattended
assert_eq "$RUN_STATUS" "1" "unattended execute failure exit status"
assert_contains "$RUN_STDOUT$RUN_STDERR" "Claude exited with status 7" "unattended status propagation"
assert_exists "$PROJECT2/.ralph/logs/OUTPUT_LOG.md" "unattended output log path"
assert_exists "$PROJECT2/.ralph/logs/ERROR_LOG.md" "unattended error log path"
assert_contains "$(cat "$PROJECT2/.ralph/logs/OUTPUT_LOG.md")" "Pass 1:" "unattended output log pass header"
assert_contains "$(cat "$PROJECT2/.ralph/logs/OUTPUT_LOG.md")" "fake-claude-stdout" "unattended output capture"
assert_contains "$(cat "$PROJECT2/.ralph/logs/ERROR_LOG.md")" "fake-claude-stderr" "unattended error capture"

# Case 3b: --unattended outside execute phase stays interactive and suppresses the unattended banner.
HOME2B="$TMP_ROOT/home-unattended-plan"
PROJECT2B="$TMP_ROOT/project-unattended-plan"
FAKE_BIN2B="$TMP_ROOT/fake-bin-unattended-plan"
ARGS_LOG2B="$TMP_ROOT/unattended-plan-args.log"
mkdir -p "$HOME2B" "$PROJECT2B/.ralph/prompts" "$PROJECT2B/.ralph/plans" "$FAKE_BIN2B"
cat > "$FAKE_BIN2B/claude" <<'EOF_FAKE_CLAUDE_UNATTENDED_PLAN'
#!/usr/bin/env bash
set -euo pipefail
: "${ARGS_LOG:?}"
{
  for arg in "$@"; do
    printf '[%s]' "$arg"
  done
  printf '\n'
} >> "$ARGS_LOG"
exit 7
EOF_FAKE_CLAUDE_UNATTENDED_PLAN
chmod +x "$FAKE_BIN2B/claude"
cat > "$PROJECT2B/.ralph/prompts/plan.md" <<'EOF_PLAN_WITH_FRONTMATTER'
---
name: plan
description: test frontmatter
---
plan prompt
EOF_PLAN_WITH_FRONTMATTER
printf 'spec\n' > "$PROJECT2B/.ralph/plans/SPECIFICATION.md"

run_start "$PROJECT2B" "$HOME2B" "$FAKE_BIN2B" env ARGS_LOG="$ARGS_LOG2B" "$START_BIN" --unattended
assert_eq "$RUN_STATUS" "1" "unattended plan failure exit status"
assert_not_contains "$RUN_STDOUT$RUN_STDERR" "Entering unattended execution loop" "unattended banner is execute-only"
UNATTENDED_PLAN_ARGS="$(cat "$ARGS_LOG2B")"
assert_contains "$UNATTENDED_PLAN_ARGS" "[--dangerously-skip-permissions]" "unattended plan still enables yolo permission flag"
assert_not_contains "$UNATTENDED_PLAN_ARGS" "[-p]" "unattended plan stays interactive"
assert_contains "$UNATTENDED_PLAN_ARGS" "[plan prompt]" "unattended plan uses plan prompt"
assert_not_contains "$UNATTENDED_PLAN_ARGS" "[name: plan]" "unattended plan strips frontmatter"

# Case 3c: plain prompts without frontmatter still pass through unchanged.
HOME2C="$TMP_ROOT/home-plan-plain"
PROJECT2C="$TMP_ROOT/project-plan-plain"
FAKE_BIN2C="$TMP_ROOT/fake-bin-plan-plain"
ARGS_LOG2C="$TMP_ROOT/plain-plan-args.log"
mkdir -p "$HOME2C" "$PROJECT2C/.ralph/prompts" "$PROJECT2C/.ralph/plans" "$FAKE_BIN2C"
cat > "$FAKE_BIN2C/claude" <<'EOF_FAKE_CLAUDE_PLAN_PLAIN'
#!/usr/bin/env bash
set -euo pipefail
: "${ARGS_LOG:?}"
{
  for arg in "$@"; do
    printf '[%s]' "$arg"
  done
  printf '\n'
} >> "$ARGS_LOG"
exit 7
EOF_FAKE_CLAUDE_PLAN_PLAIN
chmod +x "$FAKE_BIN2C/claude"
printf 'plain plan prompt\n' > "$PROJECT2C/.ralph/prompts/plan.md"
printf 'spec\n' > "$PROJECT2C/.ralph/plans/SPECIFICATION.md"

run_start "$PROJECT2C" "$HOME2C" "$FAKE_BIN2C" env ARGS_LOG="$ARGS_LOG2C" "$START_BIN"
assert_eq "$RUN_STATUS" "1" "plain plan prompt exit status"
PLAIN_PLAN_ARGS="$(cat "$ARGS_LOG2C")"
assert_contains "$PLAIN_PLAN_ARGS" "[plain plan prompt]" "plain prompt remains unchanged"

# Case 4: --freestyle --unattended normalizes to interactive yolo mode.
HOME3="$TMP_ROOT/home-freestyle"
PROJECT3="$TMP_ROOT/project-freestyle"
FAKE_BIN3="$TMP_ROOT/fake-bin-freestyle"
ARGS_LOG3="$TMP_ROOT/freestyle-args.log"
mkdir -p "$HOME3" "$PROJECT3/.ralph/prompts" "$FAKE_BIN3"
cat > "$FAKE_BIN3/claude" <<'EOF_FAKE_CLAUDE_FREESTYLE'
#!/usr/bin/env bash
set -euo pipefail
: "${ARGS_LOG:?}"
{
  for arg in "$@"; do
    printf '[%s]' "$arg"
  done
  printf '\n'
} >> "$ARGS_LOG"
exit 7
EOF_FAKE_CLAUDE_FREESTYLE
chmod +x "$FAKE_BIN3/claude"
printf 'PREPARE_PROMPT_TEXT\n' > "$PROJECT3/.ralph/prompts/prepare.md"

run_start "$PROJECT3" "$HOME3" "$FAKE_BIN3" env ARGS_LOG="$ARGS_LOG3" "$START_BIN" --freestyle --unattended
assert_eq "$RUN_STATUS" "1" "freestyle normalization exit status"
assert_not_contains "$RUN_STDOUT$RUN_STDERR" "Entering unattended execution loop" "freestyle disables unattended loop messaging"
FREESTYLE_ARGS="$(cat "$ARGS_LOG3")"
assert_contains "$FREESTYLE_ARGS" "[--dangerously-skip-permissions]" "freestyle enables yolo permission flag"
assert_not_contains "$FREESTYLE_ARGS" "[-p]" "freestyle stays interactive (no -p)"
assert_contains "$FREESTYLE_ARGS" "[PREPARE_PROMPT_TEXT]" "freestyle uses prepare prompt"

# Case 4b: freestyle mode does not run automatic handoff between passes.
HOME3B="$TMP_ROOT/home-freestyle-no-handoff"
PROJECT3B="$TMP_ROOT/project-freestyle-no-handoff"
FAKE_BIN3B="$TMP_ROOT/fake-bin-freestyle-no-handoff"
ARGS_LOG3B="$TMP_ROOT/freestyle-no-handoff-args.log"
COUNT_FILE3B="$TMP_ROOT/freestyle-no-handoff-count.txt"
mkdir -p "$HOME3B" "$PROJECT3B/.ralph/prompts" "$FAKE_BIN3B"
cat > "$FAKE_BIN3B/claude" <<'EOF_FAKE_CLAUDE_FREESTYLE_NO_HANDOFF'
#!/usr/bin/env bash
set -euo pipefail
: "${ARGS_LOG:?}"
: "${COUNT_FILE:?}"
count=0
if [[ -f "$COUNT_FILE" ]]; then
  count="$(cat "$COUNT_FILE")"
fi
count=$((count + 1))
printf '%s\n' "$count" > "$COUNT_FILE"
{
  for arg in "$@"; do
    printf '[%s]' "$arg"
  done
  printf '\n'
} >> "$ARGS_LOG"
if [[ "$count" == "1" ]]; then
  exit 0
fi
echo "freestyle no-handoff stop" >&2
exit 7
EOF_FAKE_CLAUDE_FREESTYLE_NO_HANDOFF
chmod +x "$FAKE_BIN3B/claude"
printf 'PREPARE_NO_HANDOFF_TEXT\n' > "$PROJECT3B/.ralph/prompts/prepare.md"
printf 'HANDOFF_SHOULD_NOT_RUN_TEXT\n' > "$PROJECT3B/.ralph/prompts/handoff.md"

rm -f "$ARGS_LOG3B" "$COUNT_FILE3B"
run_start "$PROJECT3B" "$HOME3B" "$FAKE_BIN3B" env ARGS_LOG="$ARGS_LOG3B" COUNT_FILE="$COUNT_FILE3B" "$START_BIN" --freestyle
assert_eq "$RUN_STATUS" "1" "freestyle no-handoff two-pass exit status"
assert_eq "$(wc -l < "$ARGS_LOG3B" | tr -d '[:space:]')" "2" "freestyle no-handoff produced two main-loop calls"
FREESTYLE_NO_HANDOFF_FIRST="$(sed -n '1p' "$ARGS_LOG3B")"
FREESTYLE_NO_HANDOFF_SECOND="$(sed -n '2p' "$ARGS_LOG3B")"
assert_contains "$FREESTYLE_NO_HANDOFF_FIRST" "[PREPARE_NO_HANDOFF_TEXT]" "freestyle no-handoff first pass uses prepare prompt"
assert_contains "$FREESTYLE_NO_HANDOFF_SECOND" "[PREPARE_NO_HANDOFF_TEXT]" "freestyle no-handoff second pass uses prepare prompt"
assert_not_contains "$FREESTYLE_NO_HANDOFF_FIRST" "[HANDOFF_SHOULD_NOT_RUN_TEXT]" "freestyle no-handoff first pass does not use handoff prompt"
assert_not_contains "$FREESTYLE_NO_HANDOFF_SECOND" "[HANDOFF_SHOULD_NOT_RUN_TEXT]" "freestyle no-handoff second pass does not use handoff prompt"
assert_not_contains "$FREESTYLE_NO_HANDOFF_SECOND" "[--continue]" "freestyle no-handoff second pass is not handoff resume call"

# Case 5: resume flags apply only on first pass for --resume and --resume <id>.
HOME4="$TMP_ROOT/home-resume"
PROJECT4="$TMP_ROOT/project-resume"
FAKE_BIN4="$TMP_ROOT/fake-bin-resume"
ARGS_LOG4="$TMP_ROOT/resume-args.log"
COUNT_FILE4="$TMP_ROOT/resume-count.txt"
mkdir -p "$HOME4" "$PROJECT4/.ralph/prompts" "$FAKE_BIN4"
cat > "$FAKE_BIN4/claude" <<'EOF_FAKE_CLAUDE_RESUME'
#!/usr/bin/env bash
set -euo pipefail
: "${ARGS_LOG:?}"
: "${COUNT_FILE:?}"
count=0
if [[ -f "$COUNT_FILE" ]]; then
  count="$(cat "$COUNT_FILE")"
fi
count=$((count + 1))
printf '%s\n' "$count" > "$COUNT_FILE"
{
  for arg in "$@"; do
    printf '[%s]' "$arg"
  done
  printf '\n'
} >> "$ARGS_LOG"
if [[ "$count" == "1" ]]; then
  exit 0
fi
echo "resume test stop" >&2
exit 7
EOF_FAKE_CLAUDE_RESUME
chmod +x "$FAKE_BIN4/claude"
printf 'PREPARE_RESUME_PROMPT_TEXT\n' > "$PROJECT4/.ralph/prompts/prepare.md"

rm -f "$ARGS_LOG4" "$COUNT_FILE4"
run_start "$PROJECT4" "$HOME4" "$FAKE_BIN4" env ARGS_LOG="$ARGS_LOG4" COUNT_FILE="$COUNT_FILE4" "$START_BIN" --resume
assert_eq "$RUN_STATUS" "1" "--resume two-pass exit status"
assert_eq "$(wc -l < "$ARGS_LOG4" | tr -d '[:space:]')" "2" "--resume produced two calls"
RESUME_FIRST="$(sed -n '1p' "$ARGS_LOG4")"
RESUME_SECOND="$(sed -n '2p' "$ARGS_LOG4")"
assert_contains "$RESUME_FIRST" "[--continue]" "--resume uses --continue on first pass"
assert_not_contains "$RESUME_FIRST" "[PREPARE_RESUME_PROMPT_TEXT]" "--resume first pass does not send phase prompt in interactive mode"
assert_not_contains "$RESUME_SECOND" "[--continue]" "--resume cleared after first pass"
assert_contains "$RESUME_SECOND" "[PREPARE_RESUME_PROMPT_TEXT]" "--resume second pass uses phase prompt after resume clears"

rm -f "$ARGS_LOG4" "$COUNT_FILE4"
run_start "$PROJECT4" "$HOME4" "$FAKE_BIN4" env ARGS_LOG="$ARGS_LOG4" COUNT_FILE="$COUNT_FILE4" "$START_BIN" --resume session-123
assert_eq "$RUN_STATUS" "1" "--resume <id> two-pass exit status"
assert_eq "$(wc -l < "$ARGS_LOG4" | tr -d '[:space:]')" "2" "--resume <id> produced two calls"
RESUME_ID_FIRST="$(sed -n '1p' "$ARGS_LOG4")"
RESUME_ID_SECOND="$(sed -n '2p' "$ARGS_LOG4")"
assert_contains "$RESUME_ID_FIRST" "[--resume][session-123]" "--resume <id> uses provided id on first pass"
assert_not_contains "$RESUME_ID_FIRST" "[PREPARE_RESUME_PROMPT_TEXT]" "--resume <id> first pass does not send phase prompt in interactive mode"
assert_not_contains "$RESUME_ID_SECOND" "[--resume]" "--resume <id> cleared after first pass"
assert_not_contains "$RESUME_ID_SECOND" "[session-123]" "--resume <id> value not reused after first pass"
assert_contains "$RESUME_ID_SECOND" "[PREPARE_RESUME_PROMPT_TEXT]" "--resume <id> second pass uses phase prompt after resume clears"

# Case 4b: unattended Claude resume sends only "continue" on first pass.
HOME4B="$TMP_ROOT/home-resume-unattended-claude"
PROJECT4B="$TMP_ROOT/project-resume-unattended-claude"
FAKE_BIN4B="$TMP_ROOT/fake-bin-resume-unattended-claude"
ARGS_LOG4B="$TMP_ROOT/resume-unattended-claude-args.log"
COUNT_FILE4B="$TMP_ROOT/resume-unattended-claude-count.txt"
mkdir -p "$HOME4B" "$PROJECT4B/.ralph/prompts" "$PROJECT4B/.ralph/plans" "$FAKE_BIN4B"
cat > "$FAKE_BIN4B/claude" <<'EOF_FAKE_CLAUDE_RESUME_UNATTENDED'
#!/usr/bin/env bash
set -euo pipefail
: "${ARGS_LOG:?}"
: "${COUNT_FILE:?}"
count=0
if [[ -f "$COUNT_FILE" ]]; then
  count="$(cat "$COUNT_FILE")"
fi
count=$((count + 1))
printf '%s\n' "$count" > "$COUNT_FILE"
{
  for arg in "$@"; do
    printf '[%s]' "$arg"
  done
  printf '\n'
} >> "$ARGS_LOG"
if [[ "$count" == "1" ]]; then
  exit 0
fi
echo "resume unattended claude stop" >&2
exit 7
EOF_FAKE_CLAUDE_RESUME_UNATTENDED
chmod +x "$FAKE_BIN4B/claude"
printf 'EXECUTE_PROMPT_TEXT\n' > "$PROJECT4B/.ralph/prompts/execute.md"
printf 'spec\n' > "$PROJECT4B/.ralph/plans/SPECIFICATION.md"
printf 'plan\n' > "$PROJECT4B/.ralph/plans/EXECUTION_PLAN.md"

rm -f "$ARGS_LOG4B" "$COUNT_FILE4B"
run_start "$PROJECT4B" "$HOME4B" "$FAKE_BIN4B" env ARGS_LOG="$ARGS_LOG4B" COUNT_FILE="$COUNT_FILE4B" "$START_BIN" --resume --unattended
assert_eq "$RUN_STATUS" "1" "--resume --unattended Claude two-pass exit status"
assert_eq "$(wc -l < "$ARGS_LOG4B" | tr -d '[:space:]')" "2" "--resume --unattended Claude produced two calls"
RESUME_UNATTENDED_CLAUDE_FIRST="$(sed -n '1p' "$ARGS_LOG4B")"
RESUME_UNATTENDED_CLAUDE_SECOND="$(sed -n '2p' "$ARGS_LOG4B")"
assert_contains "$RESUME_UNATTENDED_CLAUDE_FIRST" "[--continue][-p][continue]" "Claude unattended resume first pass uses only continue prompt"
assert_not_contains "$RESUME_UNATTENDED_CLAUDE_FIRST" "[EXECUTE_PROMPT_TEXT]" "Claude unattended resume first pass does not send phase prompt"
assert_not_contains "$RESUME_UNATTENDED_CLAUDE_SECOND" "[--continue]" "Claude unattended resume cleared after first pass"
assert_contains "$RESUME_UNATTENDED_CLAUDE_SECOND" "[-p][EXECUTE_PROMPT_TEXT]" "Claude unattended second pass uses phase prompt"

# Case 4c: interactive Codex resume does not send prompt on first pass.
HOME4C="$TMP_ROOT/home-resume-codex"
PROJECT4C="$TMP_ROOT/project-resume-codex"
FAKE_BIN4C="$TMP_ROOT/fake-bin-resume-codex"
ARGS_LOG4C="$TMP_ROOT/resume-codex-args.log"
COUNT_FILE4C="$TMP_ROOT/resume-codex-count.txt"
mkdir -p "$HOME4C" "$PROJECT4C/.ralph/prompts" "$FAKE_BIN4C"
cat > "$FAKE_BIN4C/codex" <<'EOF_FAKE_CODEX_RESUME'
#!/usr/bin/env bash
set -euo pipefail
: "${ARGS_LOG:?}"
: "${COUNT_FILE:?}"
count=0
if [[ -f "$COUNT_FILE" ]]; then
  count="$(cat "$COUNT_FILE")"
fi
count=$((count + 1))
printf '%s\n' "$count" > "$COUNT_FILE"
{
  for arg in "$@"; do
    printf '[%s]' "$arg"
  done
  printf '\n'
} >> "$ARGS_LOG"
if [[ "$count" == "1" ]]; then
  exit 0
fi
echo "resume codex stop" >&2
exit 7
EOF_FAKE_CODEX_RESUME
chmod +x "$FAKE_BIN4C/codex"
printf 'CODEX_PREPARE_PROMPT_TEXT\n' > "$PROJECT4C/.ralph/prompts/prepare.md"

rm -f "$ARGS_LOG4C" "$COUNT_FILE4C"
run_start "$PROJECT4C" "$HOME4C" "$FAKE_BIN4C" env ARGS_LOG="$ARGS_LOG4C" COUNT_FILE="$COUNT_FILE4C" "$START_BIN" --codex --resume
assert_eq "$RUN_STATUS" "1" "--codex --resume interactive two-pass exit status"
assert_eq "$(wc -l < "$ARGS_LOG4C" | tr -d '[:space:]')" "2" "--codex --resume interactive produced two calls"
RESUME_CODEX_FIRST="$(sed -n '1p' "$ARGS_LOG4C")"
RESUME_CODEX_SECOND="$(sed -n '2p' "$ARGS_LOG4C")"
assert_contains "$RESUME_CODEX_FIRST" "[resume][--last]" "Codex interactive resume first pass uses resume --last"
assert_not_contains "$RESUME_CODEX_FIRST" "[CODEX_PREPARE_PROMPT_TEXT]" "Codex interactive resume first pass does not send phase prompt"
assert_not_contains "$RESUME_CODEX_FIRST" "[continue]" "Codex interactive resume does not send continue token"
assert_not_contains "$RESUME_CODEX_SECOND" "[resume]" "Codex interactive resume cleared after first pass"
assert_contains "$RESUME_CODEX_SECOND" "[CODEX_PREPARE_PROMPT_TEXT]" "Codex interactive second pass uses phase prompt"

# Case 4d: unattended Codex resume sends only "continue" on first pass.
HOME4D="$TMP_ROOT/home-resume-unattended-codex"
PROJECT4D="$TMP_ROOT/project-resume-unattended-codex"
FAKE_BIN4D="$TMP_ROOT/fake-bin-resume-unattended-codex"
ARGS_LOG4D="$TMP_ROOT/resume-unattended-codex-args.log"
COUNT_FILE4D="$TMP_ROOT/resume-unattended-codex-count.txt"
mkdir -p "$HOME4D" "$PROJECT4D/.ralph/prompts" "$PROJECT4D/.ralph/plans" "$FAKE_BIN4D"
cat > "$FAKE_BIN4D/codex" <<'EOF_FAKE_CODEX_RESUME_UNATTENDED'
#!/usr/bin/env bash
set -euo pipefail
: "${ARGS_LOG:?}"
: "${COUNT_FILE:?}"
count=0
if [[ -f "$COUNT_FILE" ]]; then
  count="$(cat "$COUNT_FILE")"
fi
count=$((count + 1))
printf '%s\n' "$count" > "$COUNT_FILE"
{
  for arg in "$@"; do
    printf '[%s]' "$arg"
  done
  printf '\n'
} >> "$ARGS_LOG"
if [[ "$count" == "1" ]]; then
  exit 0
fi
echo "resume unattended codex stop" >&2
exit 7
EOF_FAKE_CODEX_RESUME_UNATTENDED
chmod +x "$FAKE_BIN4D/codex"
printf 'CODEX_EXECUTE_PROMPT_TEXT\n' > "$PROJECT4D/.ralph/prompts/execute.md"
printf 'spec\n' > "$PROJECT4D/.ralph/plans/SPECIFICATION.md"
printf 'plan\n' > "$PROJECT4D/.ralph/plans/EXECUTION_PLAN.md"

rm -f "$ARGS_LOG4D" "$COUNT_FILE4D"
run_start "$PROJECT4D" "$HOME4D" "$FAKE_BIN4D" env ARGS_LOG="$ARGS_LOG4D" COUNT_FILE="$COUNT_FILE4D" "$START_BIN" --codex --resume --unattended
assert_eq "$RUN_STATUS" "1" "--codex --resume --unattended two-pass exit status"
assert_eq "$(wc -l < "$ARGS_LOG4D" | tr -d '[:space:]')" "2" "--codex --resume --unattended produced two calls"
RESUME_UNATTENDED_CODEX_FIRST="$(sed -n '1p' "$ARGS_LOG4D")"
RESUME_UNATTENDED_CODEX_SECOND="$(sed -n '2p' "$ARGS_LOG4D")"
assert_contains "$RESUME_UNATTENDED_CODEX_FIRST" "[exec][resume][--last][continue]" "Codex unattended resume first pass uses only continue token"
assert_not_contains "$RESUME_UNATTENDED_CODEX_FIRST" "[CODEX_EXECUTE_PROMPT_TEXT]" "Codex unattended resume first pass does not send phase prompt"
assert_not_contains "$RESUME_UNATTENDED_CODEX_SECOND" "[resume]" "Codex unattended resume cleared after first pass"
assert_contains "$RESUME_UNATTENDED_CODEX_SECOND" "[exec][CODEX_EXECUTE_PROMPT_TEXT]" "Codex unattended second pass uses phase prompt"

# Case 6: tool selection honors USECODEX compatibility alias and explicit --claude override.
HOME5="$TMP_ROOT/home-tool-selection"
PROJECT5="$TMP_ROOT/project-tool-selection"
FAKE_BIN5="$TMP_ROOT/fake-bin-tool-selection"
TOOL_LOG5="$TMP_ROOT/tool-selection.log"
mkdir -p "$HOME5/.ralph" "$PROJECT5/.ralph/prompts" "$PROJECT5/.ralph" "$FAKE_BIN5"
cat > "$FAKE_BIN5/claude" <<'EOF_FAKE_CLAUDE_TOOL_SELECTION'
#!/usr/bin/env bash
set -euo pipefail
: "${TOOL_LOG:?}"
printf 'claude\n' >> "$TOOL_LOG"
exit 7
EOF_FAKE_CLAUDE_TOOL_SELECTION
cat > "$FAKE_BIN5/codex" <<'EOF_FAKE_CODEX_TOOL_SELECTION'
#!/usr/bin/env bash
set -euo pipefail
: "${TOOL_LOG:?}"
printf 'codex\n' >> "$TOOL_LOG"
exit 7
EOF_FAKE_CODEX_TOOL_SELECTION
chmod +x "$FAKE_BIN5/claude" "$FAKE_BIN5/codex"
printf 'PREPARE_TOOL_SELECTION_TEXT\n' > "$PROJECT5/.ralph/prompts/prepare.md"

cat > "$HOME5/.ralph/.env" <<'EOF_HOME_TOOL_SELECTION'
USECODEX=1
EOF_HOME_TOOL_SELECTION
cat > "$PROJECT5/.ralph/.env" <<'EOF_PROJECT_TOOL_SELECTION'
USECODEX=0
EOF_PROJECT_TOOL_SELECTION

rm -f "$TOOL_LOG5"
run_start "$PROJECT5" "$HOME5" "$FAKE_BIN5" env TOOL_LOG="$TOOL_LOG5" "$START_BIN"
assert_eq "$RUN_STATUS" "1" "project USECODEX override exit status"
assert_eq "$(cat "$TOOL_LOG5")" "claude" "project USECODEX override selects Claude"

cat > "$PROJECT5/.ralph/.env" <<'EOF_PROJECT_TOOL_SELECTION_CANONICAL'
USE_CODEX=1
EOF_PROJECT_TOOL_SELECTION_CANONICAL

rm -f "$TOOL_LOG5"
run_start "$PROJECT5" "$HOME5" "$FAKE_BIN5" env TOOL_LOG="$TOOL_LOG5" "$START_BIN" --claude
assert_eq "$RUN_STATUS" "1" "--claude override exit status"
assert_eq "$(cat "$TOOL_LOG5")" "claude" "--claude forces Claude over config"

# Case 6b: Claude teammate mode is validated and passed through interactive, unattended, and handoff calls.
HOME5A="$TMP_ROOT/home-teammate-mode"
PROJECT5A="$TMP_ROOT/project-teammate-mode"
FAKE_BIN5A="$TMP_ROOT/fake-bin-teammate-mode"
ARGS_LOG5A="$TMP_ROOT/teammate-mode-args.log"
COUNT_FILE5A="$TMP_ROOT/teammate-mode-count.txt"
mkdir -p "$HOME5A" "$PROJECT5A/.ralph/prompts" "$PROJECT5A/.ralph/plans" "$FAKE_BIN5A"
cat > "$FAKE_BIN5A/claude" <<'EOF_FAKE_CLAUDE_TEAMMATE_MODE'
#!/usr/bin/env bash
set -euo pipefail
: "${ARGS_LOG:?}"
: "${COUNT_FILE:?}"
count=0
if [[ -f "$COUNT_FILE" ]]; then
  count="$(cat "$COUNT_FILE")"
fi
count=$((count + 1))
printf '%s\n' "$count" > "$COUNT_FILE"
{
  for arg in "$@"; do
    printf '[%s]' "$arg"
  done
  printf '\n'
} >> "$ARGS_LOG"
if [[ "$count" == "1" ]]; then
  exit 0
fi
echo "teammate mode stop" >&2
exit 7
EOF_FAKE_CLAUDE_TEAMMATE_MODE
chmod +x "$FAKE_BIN5A/claude"
cat > "$PROJECT5A/.ralph/prompts/execute.md" <<'EOF_EXECUTE_WITH_FRONTMATTER'
---
name: execute
description: test frontmatter
---
execute prompt
EOF_EXECUTE_WITH_FRONTMATTER
cat > "$PROJECT5A/.ralph/prompts/handoff.md" <<'EOF_HANDOFF_WITH_FRONTMATTER'
---
name: handoff
description: test frontmatter
---
handoff prompt
EOF_HANDOFF_WITH_FRONTMATTER
printf 'spec\n' > "$PROJECT5A/.ralph/plans/SPECIFICATION.md"
printf 'plan\n' > "$PROJECT5A/.ralph/plans/EXECUTION_PLAN.md"

rm -f "$ARGS_LOG5A" "$COUNT_FILE5A"
run_start "$PROJECT5A" "$HOME5A" "$FAKE_BIN5A" env ARGS_LOG="$ARGS_LOG5A" COUNT_FILE="$COUNT_FILE5A" "$START_BIN" --teammate-mode tmux
assert_eq "$RUN_STATUS" "1" "--teammate-mode interactive two-pass exit status"
assert_eq "$(wc -l < "$ARGS_LOG5A" | tr -d '[:space:]')" "3" "--teammate-mode interactive execute plus handoff plus execute"
TEAMMATE_EXEC_FIRST="$(sed -n '1p' "$ARGS_LOG5A")"
TEAMMATE_HANDOFF="$(sed -n '2p' "$ARGS_LOG5A")"
TEAMMATE_EXEC_SECOND="$(sed -n '3p' "$ARGS_LOG5A")"
assert_contains "$TEAMMATE_EXEC_FIRST" "[--teammate-mode][tmux]" "interactive execute passes teammate mode"
assert_contains "$TEAMMATE_HANDOFF" "[--teammate-mode][tmux]" "interactive handoff passes teammate mode"
assert_contains "$TEAMMATE_HANDOFF" "[--continue][handoff prompt]" "interactive handoff still resumes Claude"
assert_not_contains "$TEAMMATE_HANDOFF" "[name: handoff]" "interactive handoff strips frontmatter"
assert_contains "$TEAMMATE_EXEC_SECOND" "[--teammate-mode][tmux]" "subsequent execute pass keeps teammate mode"

rm -f "$ARGS_LOG5A" "$COUNT_FILE5A"
run_start "$PROJECT5A" "$HOME5A" "$FAKE_BIN5A" env ARGS_LOG="$ARGS_LOG5A" COUNT_FILE="$COUNT_FILE5A" "$START_BIN" --unattended --teammate-mode auto
assert_eq "$RUN_STATUS" "1" "--unattended --teammate-mode exit status"
UNATTENDED_TEAMMATE_CALL="$(sed -n '1p' "$ARGS_LOG5A")"
assert_contains "$UNATTENDED_TEAMMATE_CALL" "[--teammate-mode][auto]" "unattended execute passes teammate mode"
assert_contains "$UNATTENDED_TEAMMATE_CALL" "[-p][execute prompt]" "unattended execute stays non-interactive"
assert_not_contains "$UNATTENDED_TEAMMATE_CALL" "[name: execute]" "unattended execute strips frontmatter"

# Case 6b: interactive Codex handoff strips frontmatter before resume prompt injection.
HOME5B="$TMP_ROOT/home-codex-handoff"
PROJECT5B="$TMP_ROOT/project-codex-handoff"
FAKE_BIN5B="$TMP_ROOT/fake-bin-codex-handoff"
ARGS_LOG5B="$TMP_ROOT/codex-handoff-args.log"
COUNT_FILE5B="$TMP_ROOT/codex-handoff-count.txt"
mkdir -p "$HOME5B" "$PROJECT5B/.ralph/prompts" "$PROJECT5B/.ralph/plans" "$FAKE_BIN5B"
cat > "$FAKE_BIN5B/codex" <<'EOF_FAKE_CODEX_HANDOFF'
#!/usr/bin/env bash
set -euo pipefail
: "${ARGS_LOG:?}"
: "${COUNT_FILE:?}"
count=0
if [[ -f "$COUNT_FILE" ]]; then
  count="$(cat "$COUNT_FILE")"
fi
count=$((count + 1))
printf '%s\n' "$count" > "$COUNT_FILE"
{
  for arg in "$@"; do
    printf '[%s]' "$arg"
  done
  printf '\n'
} >> "$ARGS_LOG"
if [[ "$count" == "3" ]]; then
  echo "codex handoff stop" >&2
  exit 7
fi
exit 0
EOF_FAKE_CODEX_HANDOFF
chmod +x "$FAKE_BIN5B/codex"
cat > "$PROJECT5B/.ralph/prompts/execute.md" <<'EOF_CODEX_EXECUTE_WITH_FRONTMATTER'
---
name: execute
description: test frontmatter
---
codex execute prompt
EOF_CODEX_EXECUTE_WITH_FRONTMATTER
cat > "$PROJECT5B/.ralph/prompts/handoff.md" <<'EOF_CODEX_HANDOFF_WITH_FRONTMATTER'
---
name: handoff
description: test frontmatter
---
codex handoff prompt
EOF_CODEX_HANDOFF_WITH_FRONTMATTER
printf 'spec\n' > "$PROJECT5B/.ralph/plans/SPECIFICATION.md"
printf 'plan\n' > "$PROJECT5B/.ralph/plans/EXECUTION_PLAN.md"

rm -f "$ARGS_LOG5B" "$COUNT_FILE5B"
run_start "$PROJECT5B" "$HOME5B" "$FAKE_BIN5B" env ARGS_LOG="$ARGS_LOG5B" COUNT_FILE="$COUNT_FILE5B" "$START_BIN" --codex
assert_eq "$RUN_STATUS" "1" "interactive Codex handoff three-call exit status"
assert_eq "$(wc -l < "$ARGS_LOG5B" | tr -d '[:space:]')" "3" "interactive Codex execute plus handoff plus execute"
CODEX_HANDOFF_EXEC_FIRST="$(sed -n '1p' "$ARGS_LOG5B")"
CODEX_HANDOFF_CALL="$(sed -n '2p' "$ARGS_LOG5B")"
CODEX_HANDOFF_EXEC_SECOND="$(sed -n '3p' "$ARGS_LOG5B")"
assert_contains "$CODEX_HANDOFF_EXEC_FIRST" "[codex execute prompt]" "interactive Codex execute uses stripped body prompt"
assert_not_contains "$CODEX_HANDOFF_EXEC_FIRST" "[name: execute]" "interactive Codex execute strips frontmatter"
assert_contains "$CODEX_HANDOFF_CALL" "[exec][resume][--last][codex handoff prompt]" "interactive Codex handoff resumes with stripped prompt body"
assert_not_contains "$CODEX_HANDOFF_CALL" "[name: handoff]" "interactive Codex handoff strips frontmatter"
assert_contains "$CODEX_HANDOFF_EXEC_SECOND" "[codex execute prompt]" "interactive Codex subsequent execute still uses stripped prompt body"

run_start "$PROJECT5A" "$HOME5A" "$FAKE_BIN5A" "$START_BIN" --teammate-mode invalid
assert_eq "$RUN_STATUS" "2" "--teammate-mode invalid exit status"
assert_contains "$RUN_STDERR" "--teammate-mode must be one of: auto, in-process, tmux" "--teammate-mode invalid validation message"

# Case 7: container mode uses /<basename> default workdir and honors --workdir.
HOME5="$TMP_ROOT/home-container"
PROJECT5="$TMP_ROOT/project-container-default"
FAKE_BIN5="$TMP_ROOT/fake-bin-container"
DOCKER_LOG5="$TMP_ROOT/docker-calls.log"
mkdir -p "$HOME5" "$PROJECT5/.ralph/prompts" "$PROJECT5/.ralph/plans" "$FAKE_BIN5"
cat > "$FAKE_BIN5/docker" <<'EOF_FAKE_DOCKER'
#!/usr/bin/env bash
set -euo pipefail
: "${DOCKER_LOG:?}"
if [[ "${1:-}" == "inspect" ]]; then
  echo "true"
  exit 0
fi
if [[ "${1:-}" == "exec" ]]; then
  {
    for arg in "$@"; do
      printf '[%s]' "$arg"
    done
    printf '\n'
  } >> "$DOCKER_LOG"
  echo "container exec failure" >&2
  exit 7
fi
echo "unexpected docker args: $*" >&2
exit 2
EOF_FAKE_DOCKER
chmod +x "$FAKE_BIN5/docker"
printf 'execute prompt\n' > "$PROJECT5/.ralph/prompts/execute.md"
printf 'handoff prompt\n' > "$PROJECT5/.ralph/prompts/handoff.md"
printf 'spec\n' > "$PROJECT5/.ralph/plans/SPECIFICATION.md"
printf 'plan\n' > "$PROJECT5/.ralph/plans/EXECUTION_PLAN.md"

rm -f "$DOCKER_LOG5"
run_start "$PROJECT5" "$HOME5" "$FAKE_BIN5" env DOCKER_LOG="$DOCKER_LOG5" "$START_BIN" --unattended --container test-container
assert_eq "$RUN_STATUS" "1" "container default workdir exit status"
DEFAULT_DOCKER_CALL="$(tail -n 1 "$DOCKER_LOG5")"
assert_contains "$DEFAULT_DOCKER_CALL" "[-w][/project-container-default]" "container default workdir"

rm -f "$DOCKER_LOG5"
run_start "$PROJECT5" "$HOME5" "$FAKE_BIN5" env DOCKER_LOG="$DOCKER_LOG5" "$START_BIN" --unattended --container test-container --workdir /workspace/custom
assert_eq "$RUN_STATUS" "1" "container explicit workdir exit status"
EXPLICIT_DOCKER_CALL="$(tail -n 1 "$DOCKER_LOG5")"
assert_contains "$EXPLICIT_DOCKER_CALL" "[-w][/workspace/custom]" "container explicit workdir override"

echo "test_phase8_runtime_validation.sh: PASS"
