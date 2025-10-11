{
  description = "Flake-parts module for wrapping programs with landrun sandbox";

  outputs = { ... }: {
    flakeModule = ./flake-module.nix;

    landrunModules = {
      gh = import ./modules/landrun/gh.nix;
    };
  };
}
