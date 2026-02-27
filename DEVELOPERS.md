# Ralph Developer Guide

This guide is for contributors working on Ralph itself.

**Prerequisites**
- Bash and standard Unix utilities (`mkdir`, `cat`, `sed`, `awk`).
- Git.
- Optional: Claude CLI or Codex CLI for running `ralph`, `ralph init`, and `ralph upgrade`.
- Optional: Docker or Podman if you plan to test container execution.
- Optional: beads CLI (`bd`) if you use beads-based prompts.

**Local Workflow**
- Run `ralph --help`, `ralph start --help`, `ralph init --help`, and `ralph upgrade --help` to validate CLI usage.
- Update prompt templates under `ralph/prompts/` when changing workflow guidance.
- Keep documentation in `ralph/docs/` synchronized with any behavior changes in `ralph`, `ralph init`, or `ralph upgrade`.

**Testing Expectations**
- There are no automated tests in this repository.
- Manual checks are expected after changes:
- Run `ralph --help`, `ralph start --help`, `ralph init --help`, and `ralph upgrade --help`.
- Run `bash ralph/tests/test_cli_dispatch.sh` to validate command dispatch behavior.
- Run `bash ralph/tests/test_config_precedence.sh` to validate config precedence and project-path resolution.
- Run `bash ralph/tests/test_runtime_root_enforcement.sh` to validate V2 runtime `.ralph` root enforcement diagnostics.
- Run `bash ralph/tests/test_phase8_runtime_validation.sh` to validate runtime behaviors covered by Phase 8 (missing prompt guidance, unattended logging, freestyle normalization, resume-first-pass semantics, and container workdir defaults/overrides).
- Run `bash ralph/tests/test_init_v2.sh` to validate deterministic V2 `ralph init` behavior.
- Run `bash ralph/tests/test_upgrade_v2.sh` to validate deterministic V2 `ralph upgrade` migration behavior and safety constraints.
- Run `bash ralph/tests/test_install_v2.sh` to validate V2 global install behavior and idempotency.
- If you have the CLIs installed, run a smoke test with `ralph` in a sandbox project.
- Optional: run `shellcheck ralph/ralph ralph/start ralph/init ralph/upgrade ralph/install` if you have ShellCheck installed.
