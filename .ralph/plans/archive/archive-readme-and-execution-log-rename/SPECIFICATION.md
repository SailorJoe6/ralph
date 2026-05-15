# Specification: Archive README Template, Init Integration, and OUTPUT_LOG Rename

## Purpose

Two related improvements to the Ralph workflow:

1. **Archive README template** — When a Ralph execute cycle completes, the agent archives the spec, plan, and execution log into `.ralph/plans/archive/<feature-slug>/` and updates a README.md in the archive folder. Currently, `ralph init` does not create this archive directory or seed the README, so the first archival either fails or produces an inconsistent README format. This feature ensures every newly initialized project gets a well-formatted archive README from day one.

2. **Rename OUTPUT_LOG to EXECUTION_LOG** — The file `OUTPUT_LOG.md` is renamed to `EXECUTION_LOG.md` everywhere. The new name better describes its purpose and reads more naturally when stored in the archive alongside `SPECIFICATION.md` and `EXECUTION_PLAN.md`. This is a clean break — no migration logic in `ralph upgrade` for existing projects.

## Current State

- `ralph init` creates `.ralph/plans/` and `.ralph/logs/` in the target project (line 257 of `init`).
- It does **not** create `.ralph/plans/archive/` or any README inside it.
- The ralph runtime repo has an empty `logs/` directory at the top level that is not referenced by any script. It is dead weight.
- The ralph runtime repo has a `plans/` directory at the top level that is also empty and unreferenced.
- The execution log is named `OUTPUT_LOG.md` everywhere: config variable `OUTPUT_LOG`, default path `.ralph/logs/OUTPUT_LOG.md`, and referenced in skill templates, docs, tests, and `.env.example`.

## Desired State

### 1. New template file

A new file at `plans/archive/README.example.md` in the ralph runtime repo. Contents:

```markdown
# Archive

Historical record of feature development in this repo. Each entry represents one completed Ralph design → plan → execute cycle. Each entry gives a quick description of what was landed hyperlinked to the spec/plan folder, along with the date it landed.

## Landed Features

| Feature | Landed |
|---------|--------|
| [Example feature description](example-feature/) | 2025-01-15 |
```

### 2. Changes to `ralph init`

After creating `.ralph/plans/`, init must also:

1. Create `.ralph/plans/archive/` in the target project.
2. Copy `plans/archive/README.example.md` (from the runtime) to `.ralph/plans/archive/README.md` in the target project — but only if that destination file does not already exist (idempotent).

### 3. Rename OUTPUT_LOG → EXECUTION_LOG

All references to `OUTPUT_LOG` become `EXECUTION_LOG`. The default filename changes from `OUTPUT_LOG.md` to `EXECUTION_LOG.md`. Affected locations:

**Scripts:**
- `lib/config.sh` — variable name in `RALPH_CONFIG_KEYS`, relative-path resolution case, default value assignment
- `start` — all 6 references to the `$OUTPUT_LOG` variable

**Config:**
- `.env.example` — comment and example variable

**Skill templates:**
- `skills/default/execute/SKILL.md` — archive instruction
- `skills/beads/execute/SKILL.md` — archive instruction

**Documentation:**
- `README.md` — unattended mode description and file locations section
- `docs/logging.md` — log file descriptions
- `docs/configuration.md` — variable list and path resolution note
- `docs/start.md` — handoff behavior note

**Tests:**
- `tests/test_config_precedence.sh` — assertions on default/resolved paths
- `tests/test_upgrade_v2.sh` — file creation and assertions
- `tests/test_phase8_runtime_validation.sh` — file existence and content assertions

**Archive (this repo):**
- `.ralph/plans/archive/prompts-to-skills-refactor/OUTPUT_LOG.md` → rename to `EXECUTION_LOG.md`

### 4. Cleanup

- Delete the empty top-level `logs/` directory from the ralph runtime repo. It is unreferenced by any script.

## Constraints

- Idempotent: re-running `ralph init` on a project that already has `.ralph/plans/archive/README.md` must not overwrite it.
- The `plans/` top-level directory in the runtime repo is repurposed to hold this template (and potentially future plan-related templates). It is no longer empty.
- Clean break on the rename: no backward-compatibility shims, no migration in `ralph upgrade`, no support for the old `OUTPUT_LOG` variable name.
- The `.env.example` template must use the new variable name `EXECUTION_LOG`.
- Existing tests must be updated to assert the new filename — not left passing with the old name.
