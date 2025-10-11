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
          type = types.attrsOf (types.submoduleWith {
            modules = [
              ./options.nix
              ./features.nix
              ./wrapper.nix
              { _module.args = { inherit pkgs; }; }
            ];
          });
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
