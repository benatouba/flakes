# NetCDF research environment

In a new research project, run `nix flake init -t /path/to/flakes#netcdf`,
or merge this dev shell into an existing project flake. Run `nix flake lock` and track both
`flake.nix` and `flake.lock`, then enter with `nix develop`. The template targets
`x86_64-linux`. It doesn't install Python libraries globally or write project data.

- Inspect the header with `ncdump -h input.nc`; don't dump full arrays.
- Use `xarray.open_dataset("input.nc", chunks={})` for on-disk chunks or
  `chunks="auto"` as a starting point. Select variables, time, and region before
  computing reductions. Check CF decoding, units, calendars, and missing values.
- A lazy read or small reduction needs no extra full copy. Before persistent
  rechunking or other large writes, estimate decoded bytes from shape × item size,
  count simultaneously live intermediates and final outputs, and measure a pilot.
  NetCDF compression ratios aren't a scratch-space budget.

## Large writes on ThinkPad

Run this in a project shell before starting a job that will spill or write bulk
outputs. Run the actual job in the same shell. Pick an output directory for
artifacts that need to outlive the scratch job and include it in the run manifest.

```sh
mountpoint -q /mnt || { echo '/mnt is not mounted; refusing large writes' >&2; exit 1; }
df -h /mnt
NETCDF_SCRATCH=$(mktemp -d "/mnt/netcdf-${USER}-XXXXXXXXXX") || exit 1
export NETCDF_SCRATCH
export TMPDIR="$NETCDF_SCRATCH"
```

This expects a writable `/mnt`. If it isn't writable, use a user-owned scratch
directory on that mount. Pass `$NETCDF_SCRATCH` explicitly for large intermediates;
for `dask.distributed`, set `local_directory` to it if the project adds that
package. Remove the job directory when you no longer need its intermediates.
There is no automatic fallback to home, reservation, or mount change.
