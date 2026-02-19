# Containers

Ralph's `--yolo` and `--unattended` modes give the AI full control to execute system commands. Running inside a dev container provides a sandbox so the AI can't accidentally damage your host system.

## Why Use a Container

Without a container, elevated permissions mean the AI can run any command on your machine — install packages globally, modify system files, or worse. A dev container isolates this: the AI has full control inside the container, but the blast radius is limited to that container's filesystem and processes.

## Container Requirements

Your dev container needs everything the AI will use to work on your code:

- **Build tools** — compilers, package managers, make, etc.
- **Git** — for commits, diffs, and branch operations
- **Claude CLI and/or Codex CLI** — installed and authenticated inside the container

Ensure the CLIs are authenticated before running Ralph. The simplest approach: start the container, exec in manually, run `claude` or `codex` once to authenticate, then use Ralph.

## Starting the Container

Ralph uses `docker exec` (or `podman exec`) to run commands inside an already-running container. The container must be started separately with a long-running process like `sleep infinity` so it stays alive:

```bash
# Start the container in the background
docker run -d --name my-dev -v $(pwd):/workspace my-image sleep infinity

# Authenticate the CLI inside the container
docker exec -it my-dev claude

# Now run Ralph against the container
ralph --container my-dev --workdir /workspace --yolo
```

Do **not** start the container with a command that exits (like `bash -c "echo done"`) — Ralph needs the container to be running when it execs in.

## Configuration

- `--container <name>` selects the container.
- `--workdir <path>` sets the container working directory.
- `CONTAINER_RUNTIME` sets the runtime (`docker` by default). `podman` is supported when available.
- If `--container` is provided without `--workdir`, Ralph sets `CONTAINER_WORKDIR` to `/<basename>` where `<basename>` is the current directory name on the host.

## Validation

- The container runtime must exist on PATH.
- The container must exist and be running.

## TTY Requirements

- Interactive mode requires a TTY. Ralph exits with an error if no TTY is available.
- Non-interactive mode uses `-i` only and does not require a TTY.
