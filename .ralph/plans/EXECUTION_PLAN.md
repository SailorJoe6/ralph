# Execution Plan: Finish Prompts-To-Skills Refactor

## Current Audit

The specification is not implemented yet. The repository is still in the legacy prompt-first state described by the spec:

- Runtime templates live in top-level `prompts/*.example*.md`; there is no top-level `skills/` template directory.
- This repo's active planning prompts live in `.ralph/prompts/*.md`; there is no `.ralph/skills/<phase>/SKILL.md` tree.
- `.claude/commands/*.md` and `.codex/commands/*.md` are tracked symlinks to `.ralph/prompts/*.md`; `.agents/skills/` is absent.
- `init` creates `.ralph/prompts/`, copies from `prompts/`, and exposes assistant skills by symlinking each generated `SKILL.md` back to `.ralph/prompts/<phase>.md`.
- `start` hardcodes `.ralph/prompts/<phase>.md` paths, uses top-level `prompts/prepare.example*.md` for freestyle fallback, and prints missing-prompt guidance for the prompt layout.
- `upgrade` only handles V1 `ralph/` projects, rejects any existing `.ralph/`, migrates prompts into `.ralph/prompts/`, and rewrites legacy command symlinks to `.ralph/prompts/`.
- Docs and tests still describe `.ralph/prompts/` as the current layout.

Active beads context: `ralph-fiq` is in progress and matches this spec. Open side issues `ralph-azu` and `ralph-605` are unrelated to this refactor unless their touched tests/docs overlap during implementation.

## Implementation Strategy

Work in small, testable slices. Keep migration helpers conservative: only remove or replace files that are clearly Ralph-managed, and preserve anything custom.

## Phase 1: Template And Repository Layout

1. Move bundled template files from `prompts/` to `skills/` with the same `.example` and `.example.beads` names.
2. Replace this repo's `.ralph/prompts/<phase>.md` files with `.ralph/skills/<phase>/SKILL.md`.
3. Replace checked-in `.claude/commands/<phase>.md` and `.codex/commands/<phase>.md` symlinks with `.claude/skills/<phase>` and `.codex/skills/<phase>` directory symlinks to `../../.ralph/skills/<phase>`.
4. Add `.agents/skills/<phase>` directory symlinks to `../../.ralph/skills/<phase>`.
5. Verify there are no Ralph-managed assistant integration paths that rely on symlinked `SKILL.md` files.

## Phase 2: `ralph init`

1. Rename `copy_prompt_templates` around the new skill model and create `.ralph/skills/<phase>/SKILL.md` from `skills/<phase>.example*.md`.
2. Stop creating `.ralph/prompts/` for new projects.
3. Preserve existing `.ralph/skills/<phase>/SKILL.md` files without overwriting them.
4. Change assistant setup to create directory symlinks at `.agents/skills/<phase>`, `.claude/skills/<phase>`, and `.codex/skills/<phase>` targeting `../../.ralph/skills/<phase>`.
5. Keep `.agents/skills/<phase>` creation idempotent when both `--claude` and `--codex` are used.
6. Preserve existing `--stealth` behavior: only add top-level folders created by the current init run.
7. Update help text and status messages from prompt terminology to skills terminology where user-facing.

## Phase 3: Runtime Resolver In `start`

1. Add a phase-to-instruction resolver that returns `.ralph/skills/<phase>/SKILL.md` when `.ralph/skills/` exists.
2. Support legacy `.ralph/prompts/<phase>.md` only when `.ralph/skills/` is absent and `.ralph/prompts/` exists.
3. Emit upgrade guidance whenever legacy prompt fallback is used.
4. Ensure skills win if both `.ralph/skills/` and `.ralph/prompts/` exist.
5. Update missing-file guidance to reference `.ralph/skills/<phase>/SKILL.md` and bundled `skills/*.example*.md`.
6. Keep frontmatter stripping behavior unchanged for both skill files and legacy prompts.
7. Change freestyle fallback to prefer `skills/prepare.example.beads.md`, then `skills/prepare.example.md`.
8. Update handoff prompt lookup to use the same resolver rather than the old hardcoded path.

## Phase 4: `ralph upgrade`

1. Keep existing V1 path/config/plan/log migration behavior, but migrate V1 prompts into `.ralph/skills/<phase>/SKILL.md`.
2. Add V2 old-layout migration for projects with `.ralph/prompts/` and no `.ralph/skills/`.
3. Stop rejecting all projects with existing `.ralph/`; reject only unsupported/conflicting states.
4. Preserve destination skill files that already exist with different content and warn instead of overwriting.
5. Remove `.ralph/prompts/` only when all Ralph-managed prompt files migrated and no unknown content remains.
6. Replace old assistant layouts where `<tool>/skills/<phase>/SKILL.md` is a Ralph-managed symlink with `<tool>/skills/<phase>` directory symlinks.
7. Migrate Ralph-managed `.claude/commands/<phase>.md` and `.codex/commands/<phase>.md` symlinks into assistant skill directory symlinks, create shared `.agents/skills/<phase>`, and remove only safe empty legacy command directories.
8. Preserve custom skill directories, custom command files, unrelated symlinks, and non-empty command directories.
9. Update `--stealth` to include newly created `.agents/`, `.claude/`, and `.codex/` top-level folders.
10. Make upgrade output explicitly report migrated, preserved, skipped, and repaired items.

## Phase 5: Documentation

Update at least these docs after behavior is implemented:

- `README.md`
- `docs/init.md`
- `docs/upgrade.md`
- `docs/prompts-and-plans.md`
- `docs/troubleshooting.md`
- Any docs index wording that still says prompt files are the current runtime source.

Docs must make clear that `.ralph/skills/<name>/SKILL.md` is current, `skills/*.example*.md` is the bundled source, `.ralph/prompts/` and assistant command symlinks are legacy migration inputs, and runtime strips skill frontmatter before invoking Claude or Codex.

## Phase 6: Tests

Update and run the shell test suite:

1. `bash tests/test_init_v2.sh`
2. `bash tests/test_phase8_runtime_validation.sh`
3. `bash tests/test_upgrade_v2.sh`
4. `bash tests/test_cli_dispatch.sh`
5. `bash tests/test_config_precedence.sh`
6. `bash tests/test_runtime_root_enforcement.sh`
7. `bash tests/test_install_v2.sh`

Test updates needed:

- `test_init_v2.sh`: assert `.ralph/skills/<phase>/SKILL.md`, no `.ralph/prompts/`, beads variants from `skills/`, directory symlinks, preservation of customized skills, and stealth folder rules.
- Runtime tests: assert skill lookup, frontmatter stripping, legacy fallback warning, skills-over-prompts precedence, new missing-file guidance, and new freestyle bundled fallback.
- `test_upgrade_v2.sh`: cover V1-to-skills, old V2-to-skills, old symlinked-`SKILL.md` migration, legacy command migration, custom preservation, safe cleanup, and stealth-created assistant folders.
- Other tests: replace obsolete `prompts/` expectations with `skills/` except where testing legacy fallback.

## Risks And Decisions

- Directory symlink replacement must handle both existing directories and symlinks carefully; use explicit Ralph-managed checks before removing anything.
- V2 upgrade behavior needs a clear state matrix so projects with both `.ralph/prompts/` and `.ralph/skills/` are not damaged.
- Runtime configuration still controls planning and log paths, not skill paths. The skill lookup should remain project-root based unless a future spec changes that.
- The repo currently has dirty `.beads/dolt` files from tracker activity. Do not revert them as part of this refactor.

## Completion Criteria

The work is done when the acceptance criteria in `SPECIFICATION.md` pass, relevant tests pass, `ralph-fiq` has implementation evidence, and the session completion workflow is followed through commit, `bd sync`, rebase, push, and final clean status.
