---
name: climate-data-cmip
description: Plan and inspect CF/netCDF, Zarr, xarray/Dask, and CMIP climate-data workflows.
disable-model-invocation: true
---

# Climate data and CMIP provenance

Local planning skill grounded in primary sources; not independently validated.
Work with the project's environment and already available inputs. Propose any
new downloads, dependencies, or cluster jobs separately.

1. **Identify the inputs.** State the requested quantity, domain, period, and
   resolution. Inspect metadata before reading arrays. For CMIP record activity,
   institution/model, experiment, member, table, variable, frequency, grid label,
   dataset version and access source. Confirm the files span the requested
   period without gaps or overlaps. Record citations, license and errata.
2. **Check comparability.** Inspect standard names and units, missing-value
   encodings and masks, coordinate order/longitude convention, calendar, time
   bounds and `cell_methods`. Distinguish rates from accumulations and period
   means from instantaneous values. Retain nonstandard calendars unless a
   justified conversion is part of the analysis.
3. **Design the computation.** Check grid and cell bounds/areas before averaging
   or regridding; justify weights, coverage and interpolation against the quantity.
   With xarray/Dask, align chunking to storage and the operation, subset before
   computing and estimate memory from chunk sizes. Check a small local subset
   against an expected value or invariant before scaling.
4. **Hand off.** Return a provenance table, metadata anomalies, proposed
   transformations and validation checks. Mark any uninspected metadata as
   unknown; record choices in the project's run manifest when one exists.

References: [CF Conventions](https://cfconventions.org/conventions.html),
[xarray climate](https://docs.xarray.dev/en/stable/user-guide/weather-climate.html),
[xarray and Dask](https://docs.xarray.dev/en/stable/user-guide/dask.html),
[Zarr](https://zarr.readthedocs.io/en/stable/),
[PCMDI CMIP6 data users](https://pcmdi.llnl.gov/CMIP6/Guide/dataUsers.html),
and [CMIP6 controlled vocabularies](https://github.com/WCRP-CMIP/CMIP6_CVs).
