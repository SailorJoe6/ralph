# Execution Plan: Archive README Template, Init Integration, and OUTPUT_LOG Rename

## Overview

Three work streams from the spec, plus cleanup:
1. Create the archive README template file
2. Update `ralph init` to create archive directory and copy the template
3. Rename `OUTPUT_LOG` → `EXECUTION_LOG` globally (clean break)
4. Remove dead `logs/` directory and repurpose `plans/`

## Tasks

### Task 1: Create archive README template

**File:** `plans/archive/README.example.md`

Create the template file with the exact content specified in the spec. This file serves as the seed for new projects.

**Status:** Complete

---

### Task 2: Update `ralph init` to create archive directory

**File:** `init` (lines ~257)

After the existing `mkdir -p ... .ralph/plans .ralph/logs` line, add:
1. `mkdir -p "$PROJECT_ROOT/.ralph/plans/archive"`
2. Copy `plans/archive/README.example.md` to `$PROJECT_ROOT/.ralph/plans/archive/README.md` — only if the destination does not already exist (idempotent guard).

**Status:** Complete

---

### Task 3: Rename OUTPUT_LOG → EXECUTION_LOG in `lib/config.sh`

**File:** `lib/config.sh`

Changes:
- Line 9: `OUTPUT_LOG` → `EXECUTION_LOG` in `RALPH_CONFIG_KEYS` array
- Line 112: `OUTPUT_LOG)` → `EXECUTION_LOG)` in the case statement
- Lines 232-233: variable name `OUTPUT_LOG` → `EXECUTION_LOG`, default filename `OUTPUT_LOG.md` → `EXECUTION_LOG.md`

**Status:** Complete

---

### Task 4: Rename OUTPUT_LOG → EXECUTION_LOG in `start`

**File:** `start`

All 6 references to `$OUTPUT_LOG` become `$EXECUTION_LOG`:
- Line 646: `if [[ -f "$OUTPUT_LOG" ]]`
- Line 647: `output_offset=$(wc -c < "$OUTPUT_LOG")`
- Line 656: `} >> "$OUTPUT_LOG" 2> "$ERROR_LOG"`
- Line 671: `if [[ $NONINTERACTIVE -eq 1 && -f "$OUTPUT_LOG" ]]`
- Line 672: `interrupt_detected_in_output_log "$OUTPUT_LOG" "$output_offset"`
- Line 740: `} >> "$OUTPUT_LOG" 2> "$ERROR_LOG"`

**Status:** Complete

---

### Task 5: Rename OUTPUT_LOG → EXECUTION_LOG in `.env.example`

**File:** `.env.example`

- Line 24: comment `# Default: .ralph/logs/OUTPUT_LOG.md` → `# Default: .ralph/logs/EXECUTION_LOG.md`
- Line 25: `#OUTPUT_LOG=...` → `#EXECUTION_LOG=.ralph/logs/EXECUTION_LOG.md`

**Status:** Complete

---

### Task 6: Rename OUTPUT_LOG → EXECUTION_LOG in skill templates

**Files:**
- `skills/default/execute/SKILL.md` — change `OUTPUT_LOG.md` to `EXECUTION_LOG.md`
- `skills/beads/execute/SKILL.md` — change `OUTPUT_LOG.md` to `EXECUTION_LOG.md`

**Status:** Complete

---

### Task 7: Rename OUTPUT_LOG → EXECUTION_LOG in documentation

**Files:**
- `README.md` — two references (unattended mode paragraph and file locations section)
- `docs/logging.md` — `OUTPUT_LOG` description and unattended mode note
- `docs/configuration.md` — variable list and path resolution note
- `docs/start.md` — handoff behavior note

**Status:** Complete

---

### Task 8: Rename OUTPUT_LOG → EXECUTION_LOG in tests

**Files:**
- `tests/test_config_precedence.sh` — 6 assertions referencing `OUTPUT_LOG`
- `tests/test_upgrade_v2.sh` — file creation and assertion lines
- `tests/test_phase8_runtime_validation.sh` — file existence and content assertions

**Status:** Complete

---

### Task 9: Rename archived OUTPUT_LOG.md file

**Action:** `git mv .ralph/plans/archive/prompts-to-skills-refactor/OUTPUT_LOG.md .ralph/plans/archive/prompts-to-skills-refactor/EXECUTION_LOG.md`

**Status:** Complete

---

### Task 10: Remove dead top-level `logs/` directory

**Action:** Remove `logs/.keep` from git tracking. The empty `logs/` directory (with only a `.keep` placeholder) is unreferenced by any script.

Note: git status shows this is already deleted in the working tree but not committed.

**Status:** Complete

---

### Task 11: Remove dead `.keep` files from `plans/` subdirectories

**Action:** Remove `plans/.keep`, `plans/archive/.keep`, `plans/blocked/.keep`, `plans/future/.keep` — these placeholders become unnecessary once `plans/archive/README.example.md` exists (git will track the directory via that file).

Note: git status shows these are already deleted in the working tree but not committed.

**Status:** Complete

---

## Execution Order

All tasks 1-11 are complete. Validation passed (all 5 test suites green, grep clean).

## Remaining: Documentation and Archive

All code is implemented and tested. Before archiving:

1. **Document the archive template feature in `docs/init.md`** — mention that `ralph init` now creates `.ralph/plans/archive/` and copies the README template.
2. **Archive both planning docs** — move `SPECIFICATION.md` and `EXECUTION_PLAN.md` to `.ralph/plans/archive/<slug>/` and update `.ralph/plans/archive/README.md`.

## Validation (completed)

```bash
bash tests/test_cli_dispatch.sh           # PASS
bash tests/test_config_precedence.sh      # PASS
bash tests/test_upgrade_v2.sh             # PASS
bash tests/test_phase8_runtime_validation.sh  # PASS
bash tests/test_init_v2.sh               # PASS
```

Remaining `OUTPUT_LOG` references are only in upgrade test (V1 simulation) and the spec/plan docs themselves.
