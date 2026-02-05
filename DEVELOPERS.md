# Ralph Developer Guide

This guide is for contributors working on Ralph itself.

**Prerequisites**
- Bash and standard Unix utilities (`mkdir`, `cat`, `sed`, `awk`).
- Git.
- Optional: Claude CLI or Codex CLI for running `ralph/start` and `ralph/init`.
- Optional: Docker or Podman if you plan to test container execution.
- Optional: beads CLI (`bd`) if you use beads-based prompts.

**Local Workflow**
- Run `ralph/init --help` and `ralph/start --help` to validate CLI usage.
- Update prompt templates under `ralph/prompts/` when changing workflow guidance.
- Keep documentation in `ralph/docs/` synchronized with any behavior changes in `ralph/start` or `ralph/init`.

**Testing Expectations**
- There are no automated tests in this repository.
- Manual checks are expected after changes:
- Run `ralph/start --help` and `ralph/init --help`.
- If you have the CLIs installed, run a smoke test with `ralph/start` in a sandbox project.
- Optional: run `shellcheck ralph/start ralph/init` if you have ShellCheck installed.
