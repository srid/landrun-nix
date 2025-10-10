{ lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types;
  inherit (flake-parts-lib)
    mkPerSystemOption;
in
{
  options = {
    perSystem = mkPerSystemOption
      ({ config, self', inputs', pkgs, system, ... }: {
        options.landrunApps = mkOption {
          type = types.attrsOf (types.submodule ({ name, config, ... }: {
            options = {
              program = mkOption {
                type = types.str;
                description = "The program to wrap with landrun (e.g., \${pkgs.foo}/bin/foo)";
              };

              features = mkOption {
                type = types.submodule {
                  options = {
                    tty = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Enable full TTY/terminal support for interactive applications";
                    };

                    nix = mkOption {
                      type = types.bool;
                      default = true;
                      description = "Enable access to Nix store and system paths";
                    };

                    network = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Enable network access with DNS resolution and SSL certificates";
                    };

                    tmp = mkOption {
                      type = types.bool;
                      default = true;
                      description = "Enable read-write access to /tmp for temporary files";
                    };
                  };
                };
                default = { };
                description = "High-level feature flags for common patterns";
              };

              cli = mkOption {
                type = types.submodule {
                  options = {
                    rox = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "Paths with read-only + execute access";
                    };

                    ro = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "Paths with read-only access";
                    };

                    rwx = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "Paths with read-write-execute access";
                    };

                    rw = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "Paths with read-write access";
                    };

                    env = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "Environment variables to pass through";
                    };

                    unrestrictedNetwork = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Allow unrestricted network access";
                    };

                    unrestrictedFilesystem = mkOption {
                      type = types.bool;
                      default = false;
                      description = "Allow unrestricted filesystem access";
                    };

                    addExec = mkOption {
                      type = types.bool;
                      default = true;
                      description = "Automatically add executable path to --rox";
                    };

                    extraArgs = mkOption {
                      type = types.listOf types.str;
                      default = [ ];
                      description = "Additional landrun arguments";
                    };
                  };
                };
                default = { };
                description = "Landrun CLI arguments configuration";
              };

              meta = mkOption {
                type = types.attrsOf types.anything;
                default = { };
                description = "Metadata for the wrapped package";
              };

              wrappedPackage = mkOption {
                type = types.package;
                internal = true;
                description = "The resulting wrapped package (internal)";
              };
            };

            config = {
              # Auto-configure CLI options based on high-level flags
              cli = lib.mkMerge [
                # TTY support
                (lib.mkIf config.features.tty {
                  rw = [
                    "/dev/null"
                    "/dev/tty"
                    "/dev/pts"
                    "/dev/ptmx"
                  ];
                  rox = [
                    "/dev/zero"
                    "/dev/full"
                    "/dev/random"
                    "/dev/urandom"
                    "/etc/terminfo"
                    "/usr/share/terminfo"
                  ];
                  env = [
                    "TERM"
                    "SHELL"
                    "COLORTERM"
                    "LANG"
                    "LC_ALL"
                  ];
                })

                # Nix support
                (lib.mkIf config.features.nix {
                  rox = [
                    "/nix/store"
                    "/usr"
                    "/lib"
                    "/lib64"
                  ];
                  env = [
                    "PATH"  # Required for programs to find executables
                  ];
                })

                # Network support
                (lib.mkIf config.features.network {
                  rox = [
                    "/etc/resolv.conf"
                    "/etc/ssl"
                  ];
                  unrestrictedNetwork = true;
                })

                # Tmp support
                (lib.mkIf config.features.tmp {
                  rw = [ "/tmp" ];
                })
              ];

              wrappedPackage =
                let
                  # Don't escape shell args - let them expand at runtime
                  landrunArgs = lib.concatStringsSep " \\\n      "
                    ([ ]
                      ++ (map (p: "--rox \"${p}\"") config.cli.rox)
                      ++ (map (p: "--ro \"${p}\"") config.cli.ro)
                      ++ (map (p: "--rwx \"${p}\"") config.cli.rwx)
                      ++ (map (p: "--rw \"${p}\"") config.cli.rw)
                      ++ (map (e: "--env ${e}") config.cli.env)
                      ++ (lib.optional config.cli.unrestrictedNetwork "--unrestricted-network")
                      ++ (lib.optional config.cli.unrestrictedFilesystem "--unrestricted-filesystem")
                      ++ (lib.optional config.cli.addExec "--add-exec")
                      ++ config.cli.extraArgs
                    );
                in
                (pkgs.writeShellApplication {
                  name = name;
                  runtimeInputs = [ pkgs.landrun ];
                  text = ''
                    exec landrun \
                      ${landrunArgs} \
                      ${config.program} "$@"
                  '';
                }) // {
                  meta = config.meta;
                };
            };
          }));
          default = { };
          description = "Applications to wrap with landrun sandbox";
        };

        config = {
          packages = lib.mapAttrs
            (name: cfg: cfg.wrappedPackage)
            config.landrunApps;

          apps = lib.mapAttrs
            (name: cfg: {
              type = "app";
              program = "${cfg.wrappedPackage}/bin/${name}";
              meta = cfg.meta;
            })
            config.landrunApps;
        };
      });
  };
}
