[![GitHub Discussions](https://img.shields.io/github/discussions/srid/landrun-nix)](https://github.com/srid/landrun-nix/discussions)

# landrun-nix

A Nix flake-parts module for wrapping programs with [landrun](https://github.com/Zouuup/landrun) (Landlock) sandbox.

## Usage

In your `flake.nix`:

```nix
{
  inputs.landrun-nix.url = "github:srid/landrun-nix";

  outputs = { flake-parts, landrun-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ landrun-nix.flakeModule ];

      perSystem = { pkgs, ... }: {
        landrunApps.my-app-sandboxed = {
          program = "${pkgs.my-app}/bin/my-app";
          features = {
            tty = true;      # Terminal support
            nix = true;      # Nix store access (default)
            network = true;  # Network access
            tmp = true;      # /tmp access (default)
          };
          # Raw arguments to pass to `landrun` CLI
          cli = {
            rw = [ "$HOME/.config/my-app" ];
            rox = [ "/etc/hosts" ];
          };
        };
      };
    };
}
```

Run with: `nix run .#my-app-sandboxed`

## Reusable Modules

landrun-nix provides reusable modules for common applications via `landrunModules.*`. These can be imported into your app configurations:

```nix
{
  inputs.landrun-nix.url = "github:srid/landrun-nix";

  outputs = { flake-parts, landrun-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ landrun-nix.flakeModule ];

      perSystem = { pkgs, ... }: {
        landrunApps.my-app = {
          imports = [
            landrun-nix.landrunModules.gh  # Import GitHub CLI module
          ];
          program = "${pkgs.my-app}/bin/my-app";
          features.network = true;
        };
      };
    };
}
```

### Available Modules

| Module | Description |
|--------|-------------|
| `landrunModules.gh` | GitHub CLI (`gh`) configuration with D-Bus keyring support |
| `landrunModules.git` | Git configuration with TTY support and repository access |
| `landrunModules.markitdown` | Markitdown configuration with `/proc/cpuinfo` access |

## Examples

### Claude Code

Sandbox [Claude Code](https://claude.ai/code) with access to project directory, config files, and network.

See [examples/claude-sandboxed](./examples/claude-sandboxed/flake.nix) for a complete working example.

Try it: 

```sh
nix run github:srid/landrun-nix?dir=examples/claude-sandboxed
```

## Features

High-level feature flags automatically configure common sandboxing patterns:

| Feature | Default | Description |
|---------|---------|-------------|
| `features.tty` | `false` | TTY devices, terminfo, locale env vars |
| `features.nix` | `true` | Nix store, system paths, PATH env var |
| `features.network` | `false` | DNS resolution, SSL certificates, unrestricted network |
| `features.tmp` | `true` | Read-write access to /tmp |
| `features.dbus` | `false` | D-Bus session bus, keyring access for Secret Service API |

## CLI Options

Fine-grained control via `cli.*`:

| Option | Description |
|--------|-------------|
| `rox` | Read-only + execute paths |
| `ro` | Read-only paths |
| `rwx` | Read-write-execute paths |
| `rw` | Read-write paths |
| `env` | Environment variables to pass through |
| `unrestrictedNetwork` | Allow all network access |
| `addExec` | Auto-add executable to rox (default: true) |

## Discussions

https://github.com/srid/landrun-nix/discussions

## License

GPL-3.0

## Similar projects

From [the original announcement post](https://x.com/sridca/status/1976791931431927899):

- [nixpak](https://github.com/nixpak/nixpak): a fancy declarative wrapper around bubblewrap.
- [jail.nix](https://sr.ht/~alexdavid/jail.nix/): helper to make it easy and ergonomic to wrap your derivations in bubblewrap.

