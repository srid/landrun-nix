{
  description = "Flake-parts module for wrapping programs with landrun sandbox";

  outputs = { self }: {
    flakeModule = ./modules/flake-parts/landrun;

    om.ci.default = {
      example-claude-sandboxed = {
        dir = "./examples/claude-sandboxed";
        overrideInputs.landrun-nix = self;
      };
    };

    landrunModules = {
      gh = import ./modules/landrun/gh.nix;
      git = import ./modules/landrun/git.nix;
    };
  };
}
