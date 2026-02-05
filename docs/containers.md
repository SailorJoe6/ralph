# Containers

Ralph can execute the agent inside a running container using `--container`.

**Configuration**
- `--container <name>` selects the container.
- `--workdir <path>` sets the container working directory.
- `CONTAINER_RUNTIME` sets the runtime (`docker` by default). `podman` is supported when available.
- If `--container` is provided without `--workdir`, Ralph sets `CONTAINER_WORKDIR` to `/<basename>` where `<basename>` is the current directory name on the host.

**Validation**
- The container runtime must exist on PATH.
- The container must exist and be running.

**TTY Requirements**
- Interactive mode requires a TTY. Ralph exits with an error if no TTY is available.
- Non-interactive mode uses `-i` only and does not require a TTY.
