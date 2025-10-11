{ lib, config, pkgs, name, ... }:
{
  config = {
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
}
