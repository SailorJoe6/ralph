# Callbacks

Callbacks let you insert a deterministic validation step into Ralph's loop. After each AI pass, Ralph runs your script before continuing. If the script exits non-zero, Ralph stops — giving you backpressure against the AI when builds break, tests fail, or linting errors appear.

## Why Use Callbacks

Ralph's execute loop runs the AI repeatedly, but the AI can introduce regressions or drift from project standards. A callback script is your chance to enforce deterministic checks (build, test, lint) after every pass. When a check fails, Ralph halts immediately rather than compounding the problem across further passes.

## Usage

```bash
ralph/start --callback ./validate.sh
```

## Requirements

- The script must be executable (`chmod +x`).
- The script must be resolvable via `command -v` (i.e., a path or on `$PATH`).

## Behavior

- The callback runs after every pass in all modes (interactive, unattended, and freestyle).
- The callback receives no arguments or environment variables from Ralph.
- A zero exit code means success — Ralph continues to the next pass.
- A non-zero exit code means failure — Ralph exits with an error.

## Example

A typical callback runs build, test, and lint in sequence:

```bash
#!/bin/bash
set -e
make build
make test
make lint
```

If any step fails, `set -e` causes the script to exit non-zero, which stops Ralph.
