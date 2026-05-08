# Specification: Finish Prompts-To-Skills Refactor

## Purpose

Ralph is partway through converting its assistant prompts into portable Agent Skills. The bundled prompt templates already contain skill-compatible frontmatter, and fresh `ralph init --claude` / `ralph init --codex` runs already create skill entrypoints. The remaining work is to complete the migration story so existing projects, this repository's checked-in assistant integration files, documentation, and tests all reflect the same skills-first model.

When this work is complete, Ralph-managed assistant integrations must use skill folders containing `SKILL.md` entrypoints, while legacy command symlinks are migrated or removed only when Ralph can do so without deleting user-owned command content.

## Current State

Bundled prompt templates under `prompts/` have YAML frontmatter with `name` and `description`, followed by Markdown workflow instructions. These files can serve as `SKILL.md` payloads and are still usable by Ralph runtime because `start` strips a leading YAML frontmatter block before sending prompt text to Claude or Codex.

`ralph init` copies prompt templates into `<project_root>/.ralph/prompts/` and, when `--claude` or `--codex` is used, creates skill entrypoint symlinks:

- `<project_root>/.agents/skills/<phase>/SKILL.md`
- `<project_root>/.claude/skills/<phase>/SKILL.md`
- `<project_root>/.codex/skills/<phase>/SKILL.md`

Those symlinks point back to `<project_root>/.ralph/prompts/<phase>.md`, keeping `.ralph/prompts/` as the editable source of truth.

`ralph upgrade` currently migrates V1 `ralph/` prompt files into `.ralph/prompts/` and rewrites existing `.claude/commands/*.md` / `.codex/commands/*.md` symlinks so they point at `.ralph/prompts/`. That preserves legacy command behavior, but it does not move upgraded projects onto the same skills layout produced by fresh `ralph init`.

This repository also still tracks `.claude/commands/*.md` and `.codex/commands/*.md` symlinks. Its checked-in `.ralph/prompts/*.md` files are plain prompt bodies without the skill frontmatter now present in the bundled templates.

## Desired State

Ralph's supported assistant integration model is skills-first:

- Ralph prompt bodies remain editable under `.ralph/prompts/<phase>.md`.
- Prompt files intended for skill exposure include valid YAML frontmatter with at least `name` and `description`.
- Assistant-facing entrypoints are skill folders whose `SKILL.md` files point to the corresponding `.ralph/prompts/<phase>.md` file.
- Shared open-standard skills live under `.agents/skills/<phase>/SKILL.md`.
- Claude project skills live under `.claude/skills/<phase>/SKILL.md`.
- Codex project skills live under `.codex/skills/<phase>/SKILL.md`.
- Legacy `.claude/commands/` and `.codex/commands/` Ralph symlinks are no longer created by Ralph and are not the target state for upgraded Ralph-managed integrations.

The phases covered by the integration model are:

- `design`
- `plan`
- `execute`
- `handoff`
- `prepare`
- `blocked`

## Upgrade Behavior

`ralph upgrade` must migrate legacy assistant command integrations into skills scaffolding.

If an upgraded project contains Ralph-managed legacy command symlinks under `.claude/commands/` or `.codex/commands/`, upgrade must create equivalent skill entrypoints under the new skills layout. A command symlink is Ralph-managed when it resolves to a migrated Ralph prompt under the legacy `ralph/prompts/` tree or the new `.ralph/prompts/` tree.

For each tool that has Ralph-managed legacy command symlinks:

- Create `<project_root>/.agents/skills/<phase>/SKILL.md`.
- Create `<project_root>/<tool>/skills/<phase>/SKILL.md`, where `<tool>` is `.claude` or `.codex`.
- Point each `SKILL.md` symlink at `../../../.ralph/prompts/<phase>.md`.
- Include only phases whose migrated prompt file exists.

Upgrade must remove Ralph-managed legacy command symlinks after their skill entrypoints are created. It may remove now-empty `.claude/commands/` or `.codex/commands/` directories. It must preserve custom command files, non-symlink commands, symlinks that do not resolve to Ralph prompts, and non-empty command directories.

If both `.claude` and `.codex` legacy integrations are present, shared `.agents/skills/` creation must be idempotent and must not conflict between tools. Re-running upgrade is not supported when `.ralph/` already exists, so idempotency here means duplicate creation within one upgrade run must be harmless.

With `--stealth`, upgrade must add any newly created top-level `.agents/`, `.claude/`, or `.codex/` directories to `.git/info/exclude`, using the same "only folders created by this run" rule as `ralph init`.

Upgrade must continue to honor existing safety constraints for unknown legacy `ralph/` content. Command migration must not make legacy `ralph/` cleanup less safe.

## Repository Integration State

The repository's checked-in assistant integration files should match the skills-first model used by `ralph init`:

- Replace tracked `.claude/commands/<phase>.md` symlinks with `.claude/skills/<phase>/SKILL.md` symlinks.
- Replace tracked `.codex/commands/<phase>.md` symlinks with `.codex/skills/<phase>/SKILL.md` symlinks.
- Add tracked `.agents/skills/<phase>/SKILL.md` symlinks if this repository intentionally ships shared Agent Skills entrypoints.
- Ensure tracked `.ralph/prompts/<phase>.md` files include the same skill-compatible frontmatter shape as the bundled templates, unless the project decides `.ralph/` should remain a runtime-only example state rather than a distributable integration.

The implementation should preserve the current source-of-truth rule: skill entrypoints point to `.ralph/prompts/`; they do not duplicate prompt content.

## Documentation Requirements

Documentation must describe the final skills-first model consistently:

- `README.md` should describe skills as the assistant integration mechanism and avoid implying that command symlinks are still the current Ralph-managed integration.
- `docs/init.md` should remain aligned with `ralph init` behavior.
- `docs/upgrade.md` should explain that upgrade migrates legacy command symlinks into skills scaffolding, preserves custom commands, and removes only Ralph-managed command symlinks.
- `docs/prompts-and-plans.md` should explain why prompt files carry frontmatter and why runtime strips it before sending prompts to Claude or Codex.
- Any references to `.claude/commands/` or `.codex/commands/` should clearly mark them as legacy migration inputs, not current outputs.

## Testing Requirements

Existing shell tests must cover the completed behavior.

`tests/test_init_v2.sh` should continue to verify that fresh init creates the expected skills symlinks for `.agents`, `.claude`, and `.codex`.

`tests/test_phase8_runtime_validation.sh` should continue to verify that frontmatter is stripped from runtime prompt text for Claude and Codex, including handoff paths.

`tests/test_upgrade_v2.sh` must be updated so the legacy command migration case expects skills scaffolding rather than rewritten command symlinks. It should cover:

- `.claude/commands/<phase>.md` symlink to a legacy Ralph prompt becomes `.claude/skills/<phase>/SKILL.md` plus `.agents/skills/<phase>/SKILL.md`.
- `.codex/commands/<phase>.md` symlink to a legacy Ralph prompt becomes `.codex/skills/<phase>/SKILL.md` plus `.agents/skills/<phase>/SKILL.md`.
- Migrated `SKILL.md` symlinks target `../../../.ralph/prompts/<phase>.md`.
- Ralph-managed legacy command symlinks are removed after migration.
- Custom command files and unrelated symlinks are preserved.
- Empty legacy command directories may be removed; non-empty ones remain.
- `--stealth` includes `.agents/`, `.claude/`, and `.codex/` only when those top-level folders are created by the upgrade run.

Manual validation remains aligned with `DEVELOPERS.md`: run the targeted upgrade/init tests and relevant runtime validation tests after changes.

## Non-Goals

This work does not redesign Ralph's phase model, planning document locations, runtime phase selection, or beads workflow.

This work does not introduce a second copy of prompt content under each assistant directory. Symlinks remain the expected integration mechanism.

This work does not delete user-owned custom command files.

This work does not require adding assistant-specific metadata beyond the portable skill frontmatter unless a concrete compatibility issue is found during implementation.

## Acceptance Criteria

The work is complete when:

- Bundled templates, active repository prompt files, init scaffolding, upgrade migration, docs, and tests consistently describe and exercise the skills-first model.
- Fresh `ralph init --claude --codex` and upgraded legacy projects both land on the same `.agents/skills`, `.claude/skills`, and `.codex/skills` structure for Ralph-managed phases.
- Runtime still sends prompt bodies without YAML frontmatter to Claude and Codex.
- Upgrade preserves custom command content while removing or retiring only Ralph-managed legacy command symlinks.
- The relevant shell tests pass and the evidence is recorded in the execution plan or bead notes during implementation.
