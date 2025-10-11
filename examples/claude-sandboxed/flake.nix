{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    landrun-nix.url = "github:srid/landrun-nix";
  };

  outputs = inputs@{ flake-parts, landrun-nix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ landrun-nix.flakeModule ];

      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          _module.args.pkgs = pkgs;

          landrunApps.default = {
            program = "${pkgs.claude-code}/bin/claude";
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
      };
    };
}
