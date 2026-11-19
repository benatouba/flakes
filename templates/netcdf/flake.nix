{
  description = "Project-local environment for chunked NetCDF analysis";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/04906337b6d53e8bb0eaf0470ae9f070a4d4eb55";

  outputs =
    { nixpkgs, ... }:
    {
      devShells.x86_64-linux.default =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          python = pkgs.python3.withPackages (
            ps: with ps; [
              cftime
              dask
              h5netcdf
              netcdf4
              xarray
            ]
          );
        in
        pkgs.mkShell {
          packages = [
            python
            pkgs.netcdf # ncdump, ncgen
          ];
        };
    };
}
