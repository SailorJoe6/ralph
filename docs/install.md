# Install

Ralph V2 uses a global command install model.

## Default Install Layout

- Executable wrapper: `~/.local/bin/ralph`
- Runtime files: `~/.local/share/ralph`
- User config directory: `~/.ralph`

## Initial Install

```bash
mkdir -p ~/.local/share/ralph
cd ~/.local/share/ralph
git clone git@github.com:SailorJoe6/ralph.git .
./install
```

`./install` is deterministic and idempotent. Re-running it updates existing install targets in place.

## Install Script Behavior

- Installs or overwrites `~/.local/bin/ralph`.
- Installs or refreshes runtime files at `~/.local/share/ralph`.
- Copies and overwrites `~/.ralph/.env.example`.
- Does not create `~/.ralph/.env`.

If you want user-level defaults, promote the example manually:

```bash
cp ~/.ralph/.env.example ~/.ralph/.env
```

## Updating Ralph

```bash
cd ~/.local/share/ralph
git pull origin main
./install
```

## PATH Requirement

Ensure `~/.local/bin` is on your `PATH`, or the `ralph` command will not be discoverable in new shells.
