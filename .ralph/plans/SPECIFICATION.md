# Specification: Finish Prompts-To-Skills Refactor

## Purpose

Ralph is moving from prompt files into portable Agent Skills. The current partial refactor is not sufficient because it exposes symlinked `SKILL.md` files, and some agent harnesses, including Codex, do not reliably treat a symlinked `SKILL.md` as a valid skill. Ralph must instead make each skill directory the stable unit and symlink whole skill directories into assistant-specific locations.

When this work is complete, Ralph-managed prompts are stored as skills under `.ralph/skills/<name>/SKILL.md`. Shared, Claude, and Codex skill locations point to those Ralph-managed skill directories with folder symlinks. Ralph runtime reads skill files directly, strips skill frontmatter before passing instructions to Claude or Codex, and falls back to legacy `.ralph/prompts/*.md` only for old initialized projects while clearly telling users to run `ralph upgrade`.

## Current State

Bundled templates live under `prompts/*.example.md` and `prompts/*.example.beads.md`. These files already include skill-compatible YAML frontmatter, but their location and initialization behavior still model them as flat prompt files.

`ralph init` currently copies templates into `<project_root>/.ralph/prompts/<phase>.md`. When `--claude` or `--codex` is used, it creates skill directories under `.agents/skills`, `.claude/skills`, and `.codex/skills`, but each generated `SKILL.md` is a symlink back to `.ralph/prompts/<phase>.md`. That is not compatible enough for the intended set of agent harnesses.

`start` currently resolves hardcoded prompt paths under `.ralph/prompts/` and strips a leading YAML frontmatter block before passing prompt text to Claude or Codex.

`upgrade` currently handles V1 `ralph/` layouts, migrates known prompt files into `.ralph/prompts/`, and rewrites legacy `.claude/commands/*.md` / `.codex/commands/*.md` symlinks to point at `.ralph/prompts/`. It rejects projects that already have `.ralph/`, so it cannot upgrade current V2 projects that use `.ralph/prompts/` but not `.ralph/skills/`.

This repository still tracks legacy `.claude/commands/*.md` and `.codex/commands/*.md` symlinks. Its checked-in `.ralph/prompts/*.md` files are old flat prompt bodies.

## Desired State

The canonical runtime template source is a top-level `skills/` directory in the installed Ralph runtime. The legacy top-level `prompts/` directory is removed and no longer serves as a template source.

Template files are flat files named with the existing `.example` convention:

- `skills/design.example.md`
- `skills/plan.example.md`
- `skills/execute.example.md`
- `skills/handoff.example.md`
- `skills/prepare.example.md`
- `skills/blocked.example.md`

Beads-aware variants use the same convention and are copied as `SKILL.md` during initialization:

- `skills/execute.example.beads.md`
- `skills/handoff.example.beads.md`
- `skills/prepare.example.beads.md`

No bundled `skills/<name>/` source folders or `resources/` folders are introduced in this refactor.

Initialized project state is:

- `.ralph/skills/design/SKILL.md`
- `.ralph/skills/plan/SKILL.md`
- `.ralph/skills/execute/SKILL.md`
- `.ralph/skills/handoff/SKILL.md`
- `.ralph/skills/prepare/SKILL.md`
- `.ralph/skills/blocked/SKILL.md`

Each `SKILL.md` contains YAML frontmatter with at least `name` and `description`, followed by the Markdown instructions Ralph uses as runtime prompt text after stripping frontmatter.

Assistant integration folders use directory symlinks, not symlinked `SKILL.md` files:

- `.agents/skills/<name>` is a symlink to `.ralph/skills/<name>`
- `.claude/skills/<name>` is a symlink to `.ralph/skills/<name>`
- `.codex/skills/<name>` is a symlink to `.ralph/skills/<name>`

The relative target for assistant skill directory symlinks should be `../../.ralph/skills/<name>` from `.agents/skills/<name>`, `.claude/skills/<name>`, and `.codex/skills/<name>`.

The phases covered by this model are:

- `design`
- `plan`
- `execute`
- `handoff`
- `prepare`
- `blocked`

## Init Behavior

`ralph init` must stop creating `.ralph/prompts/` for new projects. It must create `.ralph/skills/` and copy each selected template file into `.ralph/skills/<name>/SKILL.md`.

For each phase:

- Use `skills/<phase>.example.beads.md` when `--beads` is set and that file exists.
- Otherwise use `skills/<phase>.example.md`.
- Copy the selected file to `.ralph/skills/<phase>/SKILL.md`.
- Preserve an existing `.ralph/skills/<phase>/SKILL.md` without overwriting it.

When `--claude` is set, init must create:

- `.agents/skills/<phase>` symlinked to `../../.ralph/skills/<phase>`
- `.claude/skills/<phase>` symlinked to `../../.ralph/skills/<phase>`

When `--codex` is set, init must create:

- `.agents/skills/<phase>` symlinked to `../../.ralph/skills/<phase>`
- `.codex/skills/<phase>` symlinked to `../../.ralph/skills/<phase>`

If both assistant flags are set, `.agents/skills/<phase>` creation must be idempotent.

`--stealth` must include `.ralph/`, `.agents/`, `.claude/`, `.codex/`, and `.beads/` only when each top-level folder is created by the init run, consistent with current behavior.

## Runtime Behavior

`start` must resolve phase instructions through a skill-aware resolver.

Preferred lookup:

- `.ralph/skills/<phase>/SKILL.md`

Legacy fallback:

- `.ralph/prompts/<phase>.md`, but only when `.ralph/skills/` does not exist and `.ralph/prompts/` does exist.

If the fallback path is used, Ralph must print a clear warning telling the user this project uses the legacy `.ralph/prompts/` layout and that it is safe to run `ralph upgrade` to migrate it to `.ralph/skills/`.

If both `.ralph/skills/` and `.ralph/prompts/` exist, `.ralph/skills/` wins. Ralph may warn that `.ralph/prompts/` is legacy, but it must not use prompt files while skills are present.

If neither skills nor legacy prompts provide the selected phase file, Ralph must print updated creation guidance that references `skills/*.example*.md` and `.ralph/skills/<phase>/SKILL.md`, not `prompts/*.example*.md`.

Runtime must continue stripping a leading YAML frontmatter block from the selected `SKILL.md` or legacy prompt file before sending instructions to Claude or Codex. Plain legacy prompt files without frontmatter must continue to pass through unchanged.

Freestyle fallback should use the bundled `skills/prepare.example.beads.md` if available, otherwise `skills/prepare.example.md`.

## Upgrade Behavior

`ralph upgrade` must handle both legacy V1 projects and current V2 projects that predate the skills directory layout.

V1 migration:

- Source layout: `<project_root>/ralph/prompts/<phase>.md`
- Destination layout: `<project_root>/.ralph/skills/<phase>/SKILL.md`
- Existing V1 plan, log, and config migration behavior remains in scope and must continue to work.

V2 layout migration:

- Source layout: `<project_root>/.ralph/prompts/<phase>.md`
- Destination layout: `<project_root>/.ralph/skills/<phase>/SKILL.md`
- This migration is valid when `.ralph/prompts/` exists and `.ralph/skills/` does not exist.
- `ralph upgrade` must no longer reject every project that already has `.ralph/`; it must detect and handle this specific old V2 layout.

For both V1 and V2 migrations:

- Move or copy each legacy prompt into `.ralph/skills/<phase>/SKILL.md`.
- Preserve custom prompt content.
- Do not require legacy prompts to have frontmatter.
- If a destination skill already exists with different content, preserve it and warn rather than overwriting.
- Remove `.ralph/prompts/` only when all Ralph-managed prompt files have migrated and no unknown content remains.

Assistant integration migration:

- Detect old `.agents/skills/<phase>/SKILL.md`, `.claude/skills/<phase>/SKILL.md`, and `.codex/skills/<phase>/SKILL.md` layouts where the skill file is symlinked to a Ralph prompt.
- Replace each Ralph-managed old skill directory with a directory symlink to `.ralph/skills/<phase>`.
- Preserve custom skill directories that are not clearly Ralph-managed.
- Repair broken symlinks when they are clearly Ralph-managed and the destination `.ralph/skills/<phase>/SKILL.md` exists.
- Preserve any `.agents/skills/<phase>`, `.claude/skills/<phase>`, or `.codex/skills/<phase>` entry that points somewhere custom.

Legacy command migration:

- Detect `.claude/commands/<phase>.md` and `.codex/commands/<phase>.md` symlinks that resolve to Ralph-managed prompt files.
- Replace those command symlinks with `.claude/skills/<phase>` or `.codex/skills/<phase>` directory symlinks to `.ralph/skills/<phase>`.
- Also create `.agents/skills/<phase>` when any assistant-specific Ralph-managed skill integration is migrated.
- Remove only Ralph-managed command symlinks.
- Preserve custom command files, non-symlink commands, unrelated symlinks, and non-empty command directories.
- Remove empty `.claude/commands/` or `.codex/commands/` directories when safe.

With `--stealth`, upgrade must add newly created top-level `.agents/`, `.claude/`, and `.codex/` folders to `.git/info/exclude` using the same "only folders created by this run" rule as init.

Upgrade must clearly report what it migrated and what it preserved or skipped.

## Repository Integration State

This repository should match the new skills-first model:

- Replace tracked `.ralph/prompts/<phase>.md` files with `.ralph/skills/<phase>/SKILL.md` files.
- Replace tracked `.claude/commands/<phase>.md` symlinks with `.claude/skills/<phase>` directory symlinks.
- Replace tracked `.codex/commands/<phase>.md` symlinks with `.codex/skills/<phase>` directory symlinks.
- Add tracked `.agents/skills/<phase>` directory symlinks.
- Replace top-level `prompts/*.example*.md` templates with top-level `skills/*.example*.md` templates.

The repository should not rely on symlinked `SKILL.md` files anywhere in Ralph-managed assistant integration paths.

## Documentation Requirements

Documentation must describe `.ralph/skills/` as the current customization and runtime source.

Update at least:

- `README.md`
- `docs/init.md`
- `docs/upgrade.md`
- `docs/prompts-and-plans.md`
- `docs/troubleshooting.md` if prompt-missing guidance changes

Docs must explain:

- New projects customize `.ralph/skills/<name>/SKILL.md`.
- Bundled templates live under `skills/*.example*.md`.
- Beads variants are selected from `skills/*.example.beads.md` and copied to `SKILL.md`.
- `.agents/skills`, `.claude/skills`, and `.codex/skills` use symlinked skill directories.
- `.ralph/prompts/` is a legacy initialized-project layout only.
- `ralph start` can run legacy `.ralph/prompts/` projects but tells users to run `ralph upgrade`.
- `.claude/commands/` and `.codex/commands/` are legacy migration inputs, not current outputs.
- Runtime strips skill frontmatter before sending instructions to Claude or Codex.

## Testing Requirements

Shell tests must cover the new layout and migration behavior.

`tests/test_init_v2.sh` must verify:

- New init creates `.ralph/skills/<phase>/SKILL.md`, not `.ralph/prompts/<phase>.md`.
- Beads init selects `skills/*.example.beads.md` where available.
- `.agents/skills/<phase>`, `.claude/skills/<phase>`, and `.codex/skills/<phase>` are directory symlinks to `../../.ralph/skills/<phase>`.
- Existing customized `.ralph/skills/<phase>/SKILL.md` files are preserved.
- `--stealth` records newly created skill-related top-level folders correctly.

`tests/test_phase8_runtime_validation.sh` or equivalent runtime tests must verify:

- Runtime reads `.ralph/skills/<phase>/SKILL.md`.
- Frontmatter is stripped from skill files for Claude and Codex.
- Plain legacy `.ralph/prompts/<phase>.md` files still work when `.ralph/skills/` is absent.
- Legacy fallback emits guidance to run `ralph upgrade`.
- Skills win when both `.ralph/skills/` and `.ralph/prompts/` exist.
- Missing prompt guidance references `.ralph/skills/<phase>/SKILL.md` and `skills/*.example*.md`.
- Freestyle fallback uses bundled `skills/prepare.example*.md`.

`tests/test_upgrade_v2.sh` must verify:

- V1 `ralph/prompts/<phase>.md` migrates to `.ralph/skills/<phase>/SKILL.md`.
- Old V2 `.ralph/prompts/<phase>.md` migrates to `.ralph/skills/<phase>/SKILL.md`.
- Old symlinked `SKILL.md` layouts migrate to skill directory symlinks.
- Legacy `.claude/commands` and `.codex/commands` Ralph symlinks migrate to skill directory symlinks.
- Custom commands and custom skill directories are preserved.
- Empty legacy command directories and prompt directories are removed only when safe.
- `--stealth` includes `.agents/`, `.claude/`, and `.codex/` only when created by upgrade.

Existing CLI dispatch, config precedence, install, and root enforcement tests must be updated wherever they mention `prompts/`.

## Non-Goals

This work does not add `resources/` folders or multi-file bundled skill directories.

This work does not introduce extra assistant-specific skill metadata beyond the existing portable `name` and `description` frontmatter unless a concrete compatibility issue is found during implementation.

This work does not redesign Ralph's phase model, planning document paths, beads workflow, callback behavior, or container behavior.

This work does not delete user-owned custom commands or custom skill directories.

## Acceptance Criteria

The work is complete when:

- New `ralph init` runs create `.ralph/skills/<phase>/SKILL.md` and never create `.ralph/prompts/`.
- Assistant integrations use symlinked skill directories, not symlinked `SKILL.md` files.
- `ralph start` uses `.ralph/skills/<phase>/SKILL.md` first, falls back to `.ralph/prompts/<phase>.md` only for legacy projects, and tells legacy users to run `ralph upgrade`.
- `ralph upgrade` migrates both V1 `ralph/prompts` and old V2 `.ralph/prompts` projects into `.ralph/skills`.
- `ralph upgrade` migrates old assistant command and symlinked-`SKILL.md` layouts into directory symlinks while preserving custom content.
- The installed runtime no longer depends on top-level `prompts/*.example*.md` templates.
- Documentation and tests consistently describe the `.ralph/skills` model.
- Relevant shell tests pass and implementation evidence is recorded in bead notes or the execution plan.
