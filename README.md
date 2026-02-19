# Ralph - Reusable AI-Assisted Development Workflow Tool

IMPORTANT ANNOUNCEMENT: Ralph V2 is coming soon!  This will be the LAST COMMIT of Ralph V1.  Ralph V2 is a major overhaul designed to allow for a single install of the Ralph scripts, into your `~/.local/bin` directory, and then use `ralph init` in any project to set up project local configuration.  For immediate access to Ralph V2, switch to the Ralph V2 branch now!

## Introduction

Ralph implements Geoff Huntly's Ralph Wiggum loop, a design → plan → execute workflow for AI-assisted development with support for Claude and Codex CLI tools.

## What is the Ralph Wiggum loop?

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
git clone https://github.com/SailorJoe6/ralph.git ralph

# hide the ralph folder via .git/info/exclude
ralph/init

# (Optional) setup beads and create custom slash commands for claude and/or codex
ralph/init --claude --codex --beads 

# (Optional) Create .env configuration
cp ralph/.env.example ralph/.env
# Edit ralph/.env with project-specific settings
```

**Why this approach?** Cloning ralph and adding it to `.git/info/exclude` keeps ralph's git history separate from your project while keeping it undetectable in upstream diffs, and still makes it easy to update ralph independently with `git pull` from within the ralph directory.

## Prompt Customization (Required)

**IMPORTANT:** Prompts are project-specific and must be customized for your project before using ralph.

Recommended setup is to run `ralph/init` from your project root. It handles local git exclusion, prompt template copying, optional beads init, and optional command symlinks:

```bash
# Codex workflow + beads templates
ralph/init --codex --beads # initialize beads and symlink custom slash commands for codex

# Claude workflow + beads templates + Claude slash-command symlinks
ralph/init --claude --beads # initialize beads and symlink custom slash commands for claude
```

Be sure to customize the generated prompts for your project.

Manual alternative (without `ralph/init`):

```bash
# Copy example prompts (use .example.beads.md where available, otherwise use .example.md)
cp ralph/prompts/design.example.md ralph/prompts/design.md
cp ralph/prompts/plan.example.md ralph/prompts/plan.md
cp ralph/prompts/execute.example.beads.md ralph/prompts/execute.md
cp ralph/prompts/handoff.example.beads.md ralph/prompts/handoff.md
cp ralph/prompts/prepare.example.beads.md ralph/prompts/prepare.md

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

Ralph is designed to make it easy to "start from first principles" in accordance with [Geoff Huntly's video](https://youtu.be/4Nna09dG_c0?t=56) while also learining the specifics of SailorJoe's prompts.  Since e.g. `ralph/init --claude` will create custom slash commands for each of ralph's 4 prompts in your .claude/commands folder, you can actually just use these slash commands in any Claude (or Codex) session to see how it works. 

1) `/design` to experience the Q&A style specification development 
2) `/plan` to see the AI Agent build out the detailed execution plan from the spec
3) `/exeucte` for a single iteration of the AI Agent working the plan
4) `/handoff` at the end of a single iteration to plan for the next iteration by updating the plan and (optionally) beads.
5) `/clear` (or `/new`) to clear the context for the next iteration.

Repeat steps 3 - 5 as many times at needed for the AI Agent finish implementing your design step by step.  This is learning from first principles, except you're using the built in prompts instead of making them up as you go. 

Next, once you are ready to experience the actual ralph script:
```bash
# Basic usage (interactive, starts design/plan/execute based on docs)
ralph/start     # uses claude.  --codex to use codex instead. 
```

ralph/start uses the fully interactive mode in claude (or codex).  You still need to approve all commands, and you need to exit with `/quit` or CTRL+C at the end of every iteration, then the loop will continue. 

When you are ready to give the agent more autonomy: 
```bash
# Unattended execution (interactive design and plan, fulling unattended execute phase)
ralph/start --yolo        # uses interactive mode with --dangerously-skip-permissions so pair with --container (see below)
ralph/start --unattended  # uses fully unattended mode with --dangerously-skip-permissions 
```

Since `--yolo` uses interactive mode, you will be able to monitor, interupt and interact with the AI Agent.  However, you still need to end each iteration of the loop with `/quit` or CTRL+C.  Movement through the phases (including the handoff phase) will be fully automated. 

If you use `--unattended` both design and plan are interactive, allowing you to use the Q&A style design process and inspect/edit the plan and spec before moving on.  However, the execution phase will be fully unattended and run until the spec is implemented, or the agent becomes blocked, at which time it will switch back to interactive mode.  At this point, go have dinner or do something fun.  Output will be sent to the logs, so you can check on the status, but the output log is only updated once every iteration of the loop. 

Either mode uses `--dangerously-skip-permissions` so consider [running with a dev container](#container-support)

## Exiting from the loop
CTRL+C will be processed by claude or codex first, which will respond in their normal way.  Therefore, the only way to exit the ralph script is to repeatedly press CTRL+C!  

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
  -y, --yolo              Enable all permissions without unattended execution
  --codex                 Use Codex instead of Claude
  --container <name>      Execute commands inside specified container (must be already running)
  --workdir <path>        Working directory to mount into the container (default: pwd)
  --callback <script>     An optional script you write, have Ralph run it after each pass (useful for linting, format checking, etc.)
  -h, --help              Show this help message
```

## Container Support

Ralph can execute AI commands inside a running dev container:

```bash
# container must be running
docker run -d --name my-dev-container your-image-name sleep infinity

# Using default workdir (/<basename>)
ralph/start --container my-dev-container

# Custom workdir
ralph/start --container my-dev-container --workdir /your-workspace/src

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

**Yolo mode:**
```bash
ralph/start --yolo
```

Yolo mode enables full permissions but keeps the session interactive. It is intended for runs where you need elevated permissions without the unattended execute flow.


**Unattended mode:**
```bash
ralph/start --unattended
```

In unattended mode, the AI runs with elevated permissions (`--dangerously-skip-permissions` for Claude, or `--dangerously-bypass-approvals-and-sandbox` for Codex) and logs all output to `ralph/logs/OUTPUT_LOG.md` and errors to `ralph/logs/ERROR_LOG.md`.

**Important:** Unattended mode is CLI-only and cannot be enabled via `.env` or environment variables. 


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
- Handoff honors `--unattended` and `--yolo` permissions for the resume step

**Invocation:**
The handoff phase runs automatically after each execute phase pass, but only if:
- In freestyle mode, OR
- Both the specification and execution plan still exist

When using Codex, the handoff attempts to resume the exact session ID recorded in `ralph/logs/ERROR_LOG.md`. If no session ID is found, it falls back to `codex exec resume --last`.

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
