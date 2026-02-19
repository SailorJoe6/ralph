#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/config.sh
source "$RALPH_DIR/lib/config.sh"

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

clear_config_env() {
  local key=""
  for key in "${RALPH_CONFIG_KEYS[@]}"; do
    unset "$key" || true
    unset "RALPH_SHELL_HAS_${key}" || true
    unset "RALPH_SHELL_VAL_${key}" || true
  done
}

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

HOME_DIR="$TMP_ROOT/home"
PROJECT_DIR="$TMP_ROOT/project"
mkdir -p "$HOME_DIR/.ralph" "$PROJECT_DIR/.ralph"

# Case 1: defaults only
(
  export HOME="$HOME_DIR"
  rm -f "$HOME_DIR/.ralph/.env" "$PROJECT_DIR/.ralph/.env"
  clear_config_env
  ralph_load_config "$PROJECT_DIR"

  assert_eq "$SPECIFICATION" ".ralph/plans/SPECIFICATION.md" "defaults/specification"
  assert_eq "$EXECUTION_PLAN" ".ralph/plans/EXECUTION_PLAN.md" "defaults/execution_plan"
  assert_eq "$LOG_DIR" ".ralph/logs" "defaults/log_dir"
  assert_eq "$ERROR_LOG" ".ralph/logs/ERROR_LOG.md" "defaults/error_log"
  assert_eq "$OUTPUT_LOG" ".ralph/logs/OUTPUT_LOG.md" "defaults/output_log"
  assert_eq "$CONTAINER_RUNTIME" "docker" "defaults/container_runtime"
  assert_eq "$USE_CODEX" "0" "defaults/use_codex"
)

# Case 2: user .env overrides defaults
cat > "$HOME_DIR/.ralph/.env" <<'EOF'
LOG_DIR=user/logs
CONTAINER_RUNTIME=podman
USE_CODEX=1
EOF
(
  export HOME="$HOME_DIR"
  rm -f "$PROJECT_DIR/.ralph/.env"
  clear_config_env
  ralph_load_config "$PROJECT_DIR"

  assert_eq "$LOG_DIR" "user/logs" "user/log_dir"
  assert_eq "$ERROR_LOG" "user/logs/ERROR_LOG.md" "user/error_log_default_from_log_dir"
  assert_eq "$OUTPUT_LOG" "user/logs/OUTPUT_LOG.md" "user/output_log_default_from_log_dir"
  assert_eq "$CONTAINER_RUNTIME" "podman" "user/container_runtime"
  assert_eq "$USE_CODEX" "1" "user/use_codex"
)

# Case 3: project .env overrides user .env and resolves relative paths
cat > "$PROJECT_DIR/.ralph/.env" <<'EOF'
LOG_DIR=project/logs
CONTAINER_RUNTIME=nerdctl
EOF
(
  export HOME="$HOME_DIR"
  clear_config_env
  ralph_load_config "$PROJECT_DIR"

  assert_eq "$LOG_DIR" "$PROJECT_DIR/project/logs" "project/log_dir_resolved"
  assert_eq "$ERROR_LOG" "$PROJECT_DIR/project/logs/ERROR_LOG.md" "project/error_log_default_from_resolved_log_dir"
  assert_eq "$OUTPUT_LOG" "$PROJECT_DIR/project/logs/OUTPUT_LOG.md" "project/output_log_default_from_resolved_log_dir"
  assert_eq "$CONTAINER_RUNTIME" "nerdctl" "project/container_runtime"
)

# Case 4: shell environment overrides project .env
(
  export HOME="$HOME_DIR"
  clear_config_env
  export LOG_DIR="shell/logs"
  ralph_load_config "$PROJECT_DIR"

  assert_eq "$LOG_DIR" "shell/logs" "shell/log_dir"
  assert_eq "$ERROR_LOG" "shell/logs/ERROR_LOG.md" "shell/error_log_default_from_log_dir"
  assert_eq "$OUTPUT_LOG" "shell/logs/OUTPUT_LOG.md" "shell/output_log_default_from_log_dir"
)

# Case 5: project .env relative path variables resolve from project root
cat > "$PROJECT_DIR/.ralph/.env" <<'EOF'
SPECIFICATION=./docs/../docs/spec.md
EXECUTION_PLAN=plans/./EXECUTION_PLAN.md
LOG_DIR=.ralph-logs/../logs
ERROR_LOG=logs/errors.md
OUTPUT_LOG=./logs/output.md
CALLBACK=scripts/check.sh
EOF
(
  export HOME="$HOME_DIR"
  unset LOG_DIR
  clear_config_env
  ralph_load_config "$PROJECT_DIR"

  assert_eq "$SPECIFICATION" "$PROJECT_DIR/docs/spec.md" "project/specification_relative_resolution"
  assert_eq "$EXECUTION_PLAN" "$PROJECT_DIR/plans/EXECUTION_PLAN.md" "project/execution_plan_relative_resolution"
  assert_eq "$LOG_DIR" "$PROJECT_DIR/logs" "project/log_dir_relative_resolution"
  assert_eq "$ERROR_LOG" "$PROJECT_DIR/logs/errors.md" "project/error_log_relative_resolution"
  assert_eq "$OUTPUT_LOG" "$PROJECT_DIR/logs/output.md" "project/output_log_relative_resolution"
  assert_eq "$CALLBACK" "scripts/check.sh" "project/callback_not_rewritten"
)

echo "test_config_precedence.sh: PASS"
