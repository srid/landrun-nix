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

## Examples

### Claude Code

Sandbox [Claude Code](https://claude.ai/code) with access to project directory, config files, and network.

See [examples/claude-sandboxed](./examples/claude-sandboxed) for a complete working example.

```nix
landrunApps.claude-sandboxed = {
  program = lib.getExe pkgs.claude-code;
  features = {
    tty = true;
    nix = true;
    network = true;
  };
  cli = {
    rw = [
      "$HOME/.claude"
      "$HOME/.claude.json"
      "$HOME/.config/gcloud"
    ];
    rwx = [ "." ];
    env = [
      "HOME"  # Needed for gcloud and claude to resolve ~/ paths for config/state files
    ];
  };
};
```

Run with: `nix run .#claude-sandboxed`

## Features

High-level feature flags automatically configure common sandboxing patterns:

| Feature | Default | Description |
|---------|---------|-------------|
| `features.tty` | `false` | TTY devices, terminfo, locale env vars |
| `features.nix` | `true` | Nix store, system paths, PATH env var |
| `features.network` | `false` | DNS resolution, SSL certificates, unrestricted network |
| `features.tmp` | `true` | Read-write access to /tmp |

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

## License

GPL-3.0
