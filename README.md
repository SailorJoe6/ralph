# Ralph - Reusable AI-Assisted Development Workflow Tool

IMPORTANT: Ralph V2 has been merged.  Check the installation steps below to get the ralph commands available in your CLI.  If you have a the V1 ralph scripts checked out to any projects locally, upgrade them with `ralph upgrade` to get an automatic uplift to Ralph V2. 

## Introduction

Ralph implements Geoff Huntly's Ralph Wiggum loop, a design → plan → execute workflow for AI-assisted development with support for Claude and Codex CLI tools.

## What is Ralph?

Ralph orchestrates a structured workflow for AI-assisted development:

1. **Design Phase** - Discuss requirements with AI, then it generates a detailed specification
2. **Plan Phase** - AI creates detailed execution plan based on specification, you review it and work with the AI to get it perfect. 
3. **Execute Phase** - AI implements the plan one step at a time, with a clean context window for each step. Optional unattended mode for extreme productivity.
4. **Handoff Phase** - After each step, the AI updates planning docs with context for next session before clearing it's context window (runs automatically after each execute pass)

Ralph automatically progresses through phases based on which planning documents exist:
- No planning docs → runs design phase
- `SPECIFICATION.md` exists → runs plan phase
- Both specification and execution plan exist → runs execute phase (with automatic handoff after each pass)

The workflow loops continuously, allowing iterative development with AI assistance.

Each phase is kicked off with a unique tailored prompt, which you can customize to each project.  

## Installation

Install Ralph globally with the bundled install script:

```bash
# Clone Ralph runtime files to your local share directory
mkdir -p ~/.local/share/ralph
cd ~/.local/share/ralph
git clone https://github.com/SailorJoe6/ralph.git .

# Install/refresh/upgrade:
./install
```

If `ralph` is not found after install, add `~/.local/bin` to your PATH.

Then initialize each project from its root:

```bash
# Codex workflow + beads templates
ralph init --codex --beads

# Claude workflow + beads templates + Claude slash-command symlinks
ralph init --claude --beads

# Add newly-created setup folders to .git/info/exclude
ralph init --stealth --claude --codex --beads
```

## Prompt Customization (Required)

**IMPORTANT:** Prompts are project-specific and must be customized for your project before using ralph.

Recommended setup is to run [ralph init](ralph/docs/init.md) from your project root. It deterministically creates the V2 `.ralph` layout, copies prompt templates, optionally runs beads setup, and can create optional custom slash-command symlinks to allow you to "try out" our prompts:

Then customize the generated prompts for your project.

Manual alternative (without `ralph init`):

```bash
mkdir -p .ralph/prompts

# Copy example prompts from the installed runtime
# (use .example.beads.md where available, otherwise use .example.md)
cp ~/.local/share/ralph/prompts/design.example.md .ralph/prompts/design.md
cp ~/.local/share/ralph/prompts/plan.example.md .ralph/prompts/plan.md
cp ~/.local/share/ralph/prompts/execute.example.beads.md .ralph/prompts/execute.md
cp ~/.local/share/ralph/prompts/handoff.example.beads.md .ralph/prompts/handoff.md
cp ~/.local/share/ralph/prompts/prepare.example.beads.md .ralph/prompts/prepare.md
cp ~/.local/share/ralph/prompts/blocked.example.md .ralph/prompts/blocked.md

# Edit each prompt to reference your project's specific documentation
# For example, update file paths, project names, and workflow instructions
```

**What to customize:**
- File paths (e.g., `DEVELOPERS.md`, `README.md`, documentation locations)
- Project-specific workflow instructions
- Build commands and test procedures
- Project name and structure references

## Quick Start

```bash
# One-time project setup
ralph init --codex --beads
# or: ralph init --claude --beads

# Basic usage (interactive, starts design/plan/execute based on docs)
ralph --codex

# Unattended execution (interactive design and plan, fully unattended execute phase)
ralph --codex --unattended
```

## Configuration

Ralph can be configured via:
1. Command-line arguments (highest precedence)
2. Ad-hoc shell environment variables
3. Project config: `<project_root>/.ralph/.env`
4. User config: `~/.ralph/.env`
5. Script defaults (lowest precedence)

### Configuration Options

Ralph never loads `.env.example` files directly. Use them as templates to create real `.env` files (project-local or user-local):

```bash
# project config
cp ~/.local/share/ralph/.env.example .ralph/.env

# user-level defaults
mkdir -p ~/.ralph
cp ~/.ralph/.env.example ~/.ralph/.env
```

Key configuration variables:

- **Prompt paths** - Hardcoded by script (not configurable through `.env`)
- **Planning document paths** - Customize where specifications and plans are stored
- **Log configuration** - Set log directory and file paths
- **Container configuration** - Set container name, workdir, and runtime
- **Behavior flags** - Use Codex, set callbacks

Relative paths in `<project_root>/.ralph/.env` are resolved relative to `<project_root>` for planning/log path variables.

See `.env.example` for all available options with detailed comments.

## Command-Line Options

```
Usage: ralph [OPTIONS]

Options:
  -u, --unattended        Run in unattended mode (execute phase only, CLI-only)
  -f, --freestyle         Run execute loop with prepare prompt (skip spec/plan checks)
  -y, --yolo              Enable all permissions without unattended execution
  --codex                 Use Codex instead of Claude
  --container <name>      Execute commands inside specified container
  --workdir <path>        Container working directory (default: /<basename>)
  --callback <script>     Run script after each pass
  -h, --help              Show this help message
```

Subcommands:
- `ralph start` - alias for runtime mode (prints a reminder that `ralph` is all that's needed, `ralph start` is just an alias).
- `ralph init` - project setup command.
- `ralph upgrade` - migrate a legacy V1 `ralph/` layout to V2 `.ralph/`.

## Container Support

Ralph can execute AI commands inside a running dev container:

```bash
# Using default workdir (/<basename>)
ralph --container my-dev-container

# Custom workdir
ralph --container my-dev-container --workdir /workspace/myproject

# With Codex
ralph --container my-dev-container --codex
```

The default workdir is `/<basename>` where basename is your current directory name.

**Example:** Running from `/Users/name/myproject` → defaults to `/myproject`

### Container Workdir Configuration

You can set the container workdir in three ways (highest precedence first):

1. Command-line flag: `--workdir /custom/path`
2. Environment variable: `export CONTAINER_WORKDIR=/custom/path`
3. `.env` file: `CONTAINER_WORKDIR=/custom/path`

If none are set, ralph uses `/<basename>` as the default.

## Integration with AI Assistants (Optional)

For slash command support in Claude/Codex, create symlinks from your AI assistant's command directory to ralph's prompts:

```bash
mkdir -p .claude/commands
ln -s ../../.ralph/prompts/design.md .claude/commands/design.md
ln -s ../../.ralph/prompts/plan.md .claude/commands/plan.md
ln -s ../../.ralph/prompts/execute.md .claude/commands/execute.md
ln -s ../../.ralph/prompts/handoff.md .claude/commands/handoff.md
ln -s ../../.ralph/prompts/prepare.md .claude/commands/prepare.md
```

Then you can run `/design`, `/plan`, `/execute`, `/handoff`, or `/prepare` directly in your AI assistant.

**Note:** This is optional. You can always invoke ralph via `ralph` without symlinks. The handoff phase runs automatically after each execute pass, but the `/handoff` command can be useful for manual handoff preparation. The `/prepare` command is used for freestyle mode.

## Workflow Phases

### Design Phase

**When:** No planning documents exist

**What happens:**
- Interactive conversation with AI about requirements
- AI helps you think through the problem and solution
- Creates the specification document at `SPECIFICATION` (default: `.ralph/plans/SPECIFICATION.md`)
- Next run enters plan phase

**Invocation:**
```bash
ralph
```

### Plan Phase

**When:** `SPECIFICATION.md` exists but `EXECUTION_PLAN.md` doesn't

**What happens:**
- AI reads the specification
- Creates detailed implementation plan
- Creates the execution plan at `EXECUTION_PLAN` (default: `.ralph/plans/EXECUTION_PLAN.md`)
- Next run enters execute phase

**Invocation:**
```bash
ralph
```

### Execute Phase

**When:** Both `SPECIFICATION.md` and `EXECUTION_PLAN.md` exist

**What happens:**
- AI reads both specification and execution plan
- Implements the plan step by step
- Can run in interactive or unattended mode
- Loops continuously until interrupted

**Interactive mode:**
```bash
ralph
```

**Unattended mode:**
```bash
ralph --unattended
```

In unattended mode, the AI runs with elevated permissions (`--dangerously-skip-permissions` for Claude, or `--dangerously-bypass-approvals-and-sandbox` for Codex) and writes logs to `OUTPUT_LOG` and `ERROR_LOG` (defaults: `.ralph/logs/OUTPUT_LOG.md` and `.ralph/logs/ERROR_LOG.md`).

**Important:** Unattended mode is CLI-only and cannot be enabled via `.env` or environment variables. It only works with the execute phase (not freestyle mode).

**Yolo mode:**
```bash
ralph --yolo
```

Yolo mode enables full permissions but keeps the session interactive. It is intended for runs where you need elevated permissions without the unattended execute flow.

**Restrictions:**
- `--unattended` already implies full permissions, so `--yolo` is usually unnecessary when unattended mode is enabled.

### Freestyle Mode

**When:** Using `--freestyle` flag (ignores planning documents)

**What happens:**
- AI uses the `prepare.md` prompt instead of design/plan/execute workflow
- Skips specification and execution plan checks entirely
- Runs in execute loop mode (loops continuously until interrupted)
- Does not run automatic handoff between freestyle passes
- Must be run in interactive mode (unattended not supported)

**Use case:** Quick iterations or exploratory work without formal planning documents. Useful for small changes, experiments, or when you want to work without the structure of the design → plan → execute workflow.

**Invocation:**
```bash
ralph --freestyle
```

**Restrictions:**
- If you pass both `--freestyle` and `--unattended`, Ralph normalizes to interactive freestyle with yolo permissions.
- Freestyle skips project-root enforcement and resolves `.ralph/...` paths from the current directory
- Must have `.ralph/prompts/prepare.md` available in the current directory
- Still supports `--codex`, `--container`, and `--workdir` options

### Handoff Phase

**When:** Automatically runs after each execute phase pass

**What happens:**
- AI prepares to hand off work to next session/programmer
- Updates specification and execution plan with learned context
- Ensures all necessary context is captured in planning documents
- Does not create separate handoff documents

**Purpose:**
The handoff phase ensures that each work session ends with comprehensive documentation updates. This allows future sessions or programmers to pick up the work without missing context.

**Key principles:**
- Don't Repeat Yourself (DRY): Specs are for high-level design, plans are for implementation steps and current status
- Keep documentation detailed but concise
- Avoid fluff and repetition
- Update planning docs, not beads comments alone
- Handoff honors `--unattended` and `--yolo` permissions for the resume step

**Invocation:**
The handoff phase runs automatically after each execute phase pass, but only if:
- Both the specification and execution plan still exist

When using Codex, the handoff attempts to resume the exact session ID recorded in `ERROR_LOG` (default: `.ralph/logs/ERROR_LOG.md`). If no session ID is found, it falls back to `codex exec resume --last`.

If the AI completes all work and deletes the planning documents as instructed in `execute.md`, the handoff phase will be skipped (since there's nothing left to hand off).

## File Locations

### Planning Documents

V2 project scaffolding from `ralph init` is created under `.ralph/`:

- `.ralph/prompts/`
- `.ralph/plans/`
- `.ralph/logs/`
- `.ralph/.env.example`

Current runtime defaults for planning docs are:

- `.ralph/plans/SPECIFICATION.md` - Design phase output
- `.ralph/plans/EXECUTION_PLAN.md` - Planning phase output

These paths are configurable via `.env` or environment variables.

### Log Files

Current runtime defaults for logs are:

- `.ralph/logs/ERROR_LOG.md` - Error output from AI commands
- `.ralph/logs/OUTPUT_LOG.md` - Standard output in unattended mode

These paths are configurable via `.env` or environment variables.

## Updating Ralph

Update the installed runtime and refresh the wrapper/template:

```bash
cd ~/.local/share/ralph
git pull origin main
./install
```

## Resetting Workflow

To start a new design → plan → execute cycle, remove the planning documents:

```bash
rm -f .ralph/plans/SPECIFICATION.md .ralph/plans/EXECUTION_PLAN.md
```

If you changed planning paths in `.ralph/.env`, remove those configured files instead.

Next `ralph` will begin at the design phase.

## Troubleshooting

### Container not found

If you get "Error: container not found", verify the container is running:

```bash
docker ps
# or
podman ps
```

### Container workdir doesn't exist

If the workdir doesn't exist in the container, docker/podman exec will fail. Either:

1. Create the directory in the container, or
2. Use `--workdir` to specify an existing directory

### Permission denied on Ralph scripts

Make sure the scripts are executable:

```bash
chmod +x ralph/ralph ralph/start ralph/init ralph/upgrade
```

### Claude/Codex not found

Ensure Claude Code or Codex CLI is installed and in your PATH:

```bash
which claude
# or
which codex
```

## Examples

### Basic interactive workflow

```bash
# Start design phase
ralph

# After specification is created, run plan phase
ralph

# After plan is created, run execute phase
ralph
```

### Unattended execution with callback

```bash
# Create a callback script to run tests after each pass
cat > validate.sh << 'EOF'
#!/bin/bash
echo "Running tests..."
make test
EOF
chmod +x validate.sh

# Run unattended with callback
ralph --unattended --callback ./validate.sh
```

### Container-based development

```bash
# Start dev container
docker run -d --name my-dev -v $(pwd):/workspace my-image

# Run ralph in container
ralph --container my-dev --workdir /workspace
```

### Codex instead of Claude

```bash
# Use Codex for all phases
ralph --codex

# Or set in .env
echo "USE_CODEX=1" >> .ralph/.env
ralph
```

## License

Public domain. Use freely.

## Contributing

This is a personal workflow tool. Feel free to fork and customize for your needs.
