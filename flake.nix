{
  description = "Flake-parts module for wrapping programs with landrun sandbox";

  outputs = { ... }: {
    flakeModule = ./flake-module.nix;
  };
}
