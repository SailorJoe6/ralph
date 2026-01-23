# Ralph - Reusable AI-Assisted Development Workflow Tool

Ralph implements a design → plan → execute workflow for AI-assisted development with support for Claude and Codex CLI tools.

## What is Ralph?

Ralph orchestrates a structured workflow for AI-assisted development:

1. **Design Phase** - Discuss requirements with AI, create specification
2. **Plan Phase** - AI creates detailed execution plan based on specification
3. **Execute Phase** - AI implements the plan with optional unattended mode
4. **Handoff Phase** - AI updates planning docs with context for next session (runs automatically after each execute pass)

Ralph automatically progresses through phases based on which planning documents exist:
- No planning docs → runs design phase
- `SPECIFICATION.md` exists → runs plan phase
- Both specification and execution plan exist → runs execute phase (with automatic handoff after each pass)

The workflow loops continuously, allowing iterative development with AI assistance.

## Installation

Clone ralph into your project and add it to the parent repo's git exclude file:

```bash
# Clone ralph into your project
git clone https://github.com/<username>/ralph.git ralph

# Add to .git/info/exclude to keep ralph separate from your project
echo "ralph/" >> .git/info/exclude

# (Optional) Create .env configuration
cp ralph/.env.example ralph/.env
# Edit ralph/.env with project-specific settings
```

**Why this approach?** Cloning ralph and adding it to `.git/info/exclude` keeps ralph's git history separate from your project while keeping it undetectable in upstream diffs, and still makes it easy to update ralph independently with `git pull` from within the ralph directory.

## Prompt Customization (Required)

**IMPORTANT:** Prompts are project-specific and must be customized for your project before using ralph.

Ralph's prompts reference project-specific documentation (like `DEVELOPERS.md`, `docs/README.md`, etc.). You must copy the example prompts and customize them for your project:

```bash
# Copy example prompts
cp ralph/prompts/design.example.md ralph/prompts/design.md
cp ralph/prompts/plan.example.md ralph/prompts/plan.md
cp ralph/prompts/execute.example.md ralph/prompts/execute.md
cp ralph/prompts/handoff.example.md ralph/prompts/handoff.md
cp ralph/prompts/prepare.example.md ralph/prompts/prepare.md

# Edit each prompt to reference your project's specific documentation
# For example, update file paths, project names, and workflow instructions
```

The `.example.md` files are templates committed to the ralph repository. The actual `.md` files are gitignored and project-specific.

**What to customize:**
- File paths (e.g., `DEVELOPERS.md`, `README.md`, documentation locations)
- Project-specific workflow instructions
- Build commands and test procedures
- Project name and structure references

## Quick Start

```bash
# Basic usage (interactive)
ralph/start

# Unattended execution (execute phase only)
ralph/start --unattended

# Use Codex instead of Claude
ralph/start --codex
```

## Configuration

Ralph can be configured via:
1. Command-line arguments (highest precedence)
2. Environment variables
3. `.env` file (copy from `.env.example`)
4. Script defaults (lowest precedence)

### Configuration Options

Copy `.env.example` to `.env` and customize:

```bash
cp ralph/.env.example ralph/.env
```

Key configuration variables:

- **Prompt paths** - Customize locations of design/plan/execute prompts
- **Planning document paths** - Customize where specifications and plans are stored
- **Log configuration** - Set log directory and file paths
- **Container configuration** - Set container name, workdir, and runtime
- **Behavior flags** - Use Codex, set callbacks

See `.env.example` for all available options with detailed comments.

## Command-Line Options

```
Usage: ralph/start [OPTIONS]

Options:
  -u, --unattended        Run in unattended mode (execute phase only, CLI-only)
  -f, --freestyle         Run execute loop with prepare prompt (skip spec/plan checks)
  --codex                 Use Codex instead of Claude
  --container <name>      Execute commands inside specified container
  --workdir <path>        Container working directory (default: /<basename>)
  --callback <script>     Run script after each pass
  -h, --help              Show this help message
```

## Container Support

Ralph can execute AI commands inside a running dev container:

```bash
# Using default workdir (/<basename>)
ralph/start --container my-dev-container

# Custom workdir
ralph/start --container my-dev-container --workdir /workspace/myproject

# With Codex
ralph/start --container my-dev-container --codex
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
ln -s ../../ralph/prompts/design.md .claude/commands/design.md
ln -s ../../ralph/prompts/plan.md .claude/commands/plan.md
ln -s ../../ralph/prompts/execute.md .claude/commands/execute.md
ln -s ../../ralph/prompts/handoff.md .claude/commands/handoff.md
ln -s ../../ralph/prompts/prepare.md .claude/commands/prepare.md
```

Then you can run `/design`, `/plan`, `/execute`, `/handoff`, or `/prepare` directly in your AI assistant.

**Note:** This is optional. You can always invoke ralph via `ralph/start` without symlinks. The handoff phase runs automatically after each execute pass, but the `/handoff` command can be useful for manual handoff preparation. The `/prepare` command is used for freestyle mode.

## Workflow Phases

### Design Phase

**When:** No planning documents exist

**What happens:**
- Interactive conversation with AI about requirements
- AI helps you think through the problem and solution
- Creates `ralph/plans/SPECIFICATION.md` with detailed specification
- Next run enters plan phase

**Invocation:**
```bash
ralph/start
```

### Plan Phase

**When:** `SPECIFICATION.md` exists but `EXECUTION_PLAN.md` doesn't

**What happens:**
- AI reads the specification
- Creates detailed implementation plan
- Creates `ralph/plans/EXECUTION_PLAN.md` with step-by-step plan
- Next run enters execute phase

**Invocation:**
```bash
ralph/start
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
ralph/start
```

**Unattended mode:**
```bash
ralph/start --unattended
```

In unattended mode, the AI runs with `--dangerously-skip-permissions` and logs all output to `ralph/logs/OUTPUT_LOG.md` and errors to `ralph/logs/ERROR_LOG.md`.

**Important:** Unattended mode is CLI-only and cannot be enabled via `.env` or environment variables. It only works with the execute phase (not freestyle mode).

### Freestyle Mode

**When:** Using `--freestyle` flag (ignores planning documents)

**What happens:**
- AI uses the `prepare.md` prompt instead of design/plan/execute workflow
- Skips specification and execution plan checks entirely
- Runs in execute loop mode (loops continuously until interrupted)
- Handoff runs automatically after each freestyle pass
- Must be run in interactive mode (unattended not supported)

**Use case:** Quick iterations or exploratory work without formal planning documents. Useful for small changes, experiments, or when you want to work without the structure of the design → plan → execute workflow.

**Invocation:**
```bash
ralph/start --freestyle
```

**Restrictions:**
- Cannot be combined with `--unattended` (freestyle requires interactive input)
- Must have `ralph/prompts/prepare.md` customized for your project
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

**Invocation:**
The handoff phase runs automatically after each execute phase pass, but only if:
- In freestyle mode, OR
- Both the specification and execution plan still exist

If the AI completes all work and deletes the planning documents as instructed in `execute.md`, the handoff phase will be skipped (since there's nothing left to hand off).

## File Locations

### Planning Documents

By default, planning documents are stored in `ralph/plans/` (gitignored):

- `ralph/plans/SPECIFICATION.md` - Design phase output
- `ralph/plans/EXECUTION_PLAN.md` - Planning phase output

These paths are configurable via `.env` or environment variables.

### Log Files

Log files are created under `ralph/logs/` (gitignored):

- `ralph/logs/ERROR_LOG.md` - Error output from AI commands
- `ralph/logs/OUTPUT_LOG.md` - Standard output in unattended mode

These paths are configurable via `.env` or environment variables.

## Updating Ralph

Since ralph is a regular git clone (not a submodule), you can update it easily:

```bash
cd ralph
git pull origin main
cd ..
```

## Resetting Workflow

To start a new design → plan → execute cycle, remove the planning documents:

```bash
rm -f ralph/plans/SPECIFICATION.md ralph/plans/EXECUTION_PLAN.md
```

Next `ralph/start` will begin at the design phase.

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

### Permission denied on start script

Make sure the script is executable:

```bash
chmod +x ralph/start
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
ralph/start

# After specification is created, run plan phase
ralph/start

# After plan is created, run execute phase
ralph/start
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
ralph/start --unattended --callback ./validate.sh
```

### Container-based development

```bash
# Start dev container
docker run -d --name my-dev -v $(pwd):/workspace my-image

# Run ralph in container
ralph/start --container my-dev --workdir /workspace
```

### Codex instead of Claude

```bash
# Use Codex for all phases
ralph/start --codex

# Or set in .env
echo "USE_CODEX=1" >> ralph/.env
ralph/start
```

## License

Public domain. Use freely.

## Contributing

This is a personal workflow tool. Feel free to fork and customize for your needs.
