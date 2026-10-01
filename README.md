# mise-gnucobol

A [mise](https://mise.jdx.dev) plugin that installs [GnuCOBOL](https://gnucobol.sourceforge.io/) by building it from source.

## Install

```bash
mise plugin install gnucobol https://github.com/Naitsabot/mise-gnucobol
mise use gnucobol@3.2
cobc --version
```

## Requirements

GnuCOBOL is compiled during install, so these must be present first:

- A C toolchain (`gcc` and `make`)
- GMP, ncurses, Berkeley DB, json-c and libxml2 development packages

```bash
# Debian/Ubuntu
sudo apt install build-essential libgmp-dev libncurses-dev libdb-dev libjson-c-dev libxml2-dev

# Arch
sudo pacman -S base-devel gmp ncurses db json-c libxml2

# macOS (Homebrew)
brew install gmp ncurses berkeley-db json-c libxml2
```

On macOS, Homebrew's `berkeley-db` is required. The `db.h` shipped with the SDK cannot be used.

## Platforms

Linux and macOS. Windows is not supported; use WSL.

## Development Workflow

### Setting up development environment

1. Install pre-commit hooks (optional but recommended):
```bash
hk install
```

This sets up automatic linting and formatting on git commits.

### Local Testing

1. Link your plugin for development:
```bash
mise plugin link --force <TOOL> .
```

2. Run tests:
```bash
mise run test
```

3. Run linting:
```bash
mise run lint
```

4. Run full CI suite:
```bash
mise run ci
```

### Debugging

Enable debug output:
```bash
MISE_DEBUG=1 mise install <TOOL>@latest
```

## License

MIT