# Configuration

Ralph runtime commands (`ralph`, `ralph start`, `ralph init`, `ralph upgrade`) share one config-loading layer.

Prompt file paths are hardcoded by runtime script and are not loaded from `.env`.

**Precedence (highest -> lowest)**
- CLI flags
- Shell environment variables
- Project config: `<project_root>/.ralph/.env`
- User config: `~/.ralph/.env`
- Script defaults

`UNATTENDED` is CLI-only and ignores environment values.

Ralph never loads from `.env.example` files.

**Relative Path Resolution**
- Relative paths in `<project_root>/.ralph/.env` are resolved relative to `<project_root>` for `SPECIFICATION`, `EXECUTION_PLAN`, `LOG_DIR`, `ERROR_LOG`, and `OUTPUT_LOG`.

Relative values in `~/.ralph/.env` and shell environment variables are used as written.

**Defaults (current runtime behavior)**
- `SPECIFICATION=.ralph/plans/SPECIFICATION.md`
- `EXECUTION_PLAN=.ralph/plans/EXECUTION_PLAN.md`
- `LOG_DIR=.ralph/logs`
- `ERROR_LOG=${LOG_DIR}/ERROR_LOG.md`
- `OUTPUT_LOG=${LOG_DIR}/OUTPUT_LOG.md`
- `CONTAINER_NAME=` (empty)
- `CONTAINER_WORKDIR=` (empty; runtime computes `/<basename>` when `--container` is set without `--workdir`)
- `CONTAINER_RUNTIME=docker`
- `USE_CODEX=0`
- `CALLBACK=` (empty)

---

**Next:** [containers.md](containers.md) - Container runtime behavior, workdir defaults, and TTY rules.
