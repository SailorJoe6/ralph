# Configuration

Ralph loads configuration from `ralph/.env` if present, then applies defaults and CLI overrides. Prompt file paths are hardcoded and not configurable.

**Precedence**
- CLI flags override environment variables.
- Environment variables override defaults.
- `UNATTENDED` is CLI-only and ignores environment values.

**Planning Docs**
- `SPECIFICATION` default: `ralph/plans/SPECIFICATION.md`
- `EXECUTION_PLAN` default: `ralph/plans/EXECUTION_PLAN.md`

**Logging**
- `LOG_DIR` default: `ralph/logs`
- `ERROR_LOG` default: `${LOG_DIR}/ERROR_LOG.md`
- `OUTPUT_LOG` default: `${LOG_DIR}/OUTPUT_LOG.md`
- Legacy `OUT_LOG` is not read by the current script.

**Behavior Flags**
- `USE_CODEX` default: `0`
- `FREESTYLE` default: `0`
- `YOLO` default: `0`
- `RESUME_MODE` default: `0`
- `RESUME_SESSION` default: empty
- `CALLBACK` default: empty

**Container Settings**
- `CONTAINER_NAME` default: empty
- `CONTAINER_RUNTIME` default: `docker`
- `CONTAINER_WORKDIR` default: empty, then set to `/<basename>` when `--container` is used and no workdir is provided
