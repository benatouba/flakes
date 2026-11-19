# Research tools on ThinkPad

The desktop branch shares the three pinned K-Dense skills and the local
`scientific-reproducibility` skill between Claude Code and OpenCode. Skill
instructions do not install project dependencies. For chunked NetCDF analysis,
start with the [project template](../../../templates/netcdf/README.md), including its
`/mnt` scratch guidance. DuckDB is optional for smaller derived Parquet tables;
there is no DuckDB installation or Jupyter MCP bridge in the default setup.

## Reproducibility

Record actual execution in a project run manifest. When you need versioned
large inputs and command replay, evaluate [DataLad](https://handbook.datalad.org/)
in the project. For repeated multistage workflows, use a pinned
[Snakemake](https://snakemake.readthedocs.io/) project environment. Neither is
installed globally.

## Context Mode

Both clients use the same pinned local plugin. The managed `claude` launcher
adds the inline plugin with hooks and MCP, without changing existing Claude
settings or credentials. Check `/hooks` and `/mcp` in a new Claude Code session.
OpenCode replaces DCP with Context Mode and keeps native compaction. Check
that `ctx_doctor` is available in a session; use `/reload` if needed. In
OpenCode 2.3.0, `opencode plugin list` does not show this local plugin.

Update the version and artifact hash in
[`pkgs/context-mode-agent/default.nix`](../../../pkgs/context-mode-agent/default.nix),
not via the plugin's self-upgrade tool. To roll back the OpenCode trial, restore
`@tarquinen/opencode-dcp@3.2.1` in the managed OpenCode config; the existing
unmanaged `dcp.jsonc` is not migrated. Compare billable input (including cache
reads/writes), output, and result quality on the same task and model before
concluding the trial saves money.

Tool results can be indexed on disk. This flake does not persist the index or
configure a hosted Gateway. Keep sensitive data out of indexed tool results;
the index is not a provenance record or a permissions boundary.

## OpenAlex (project opt-in)

From the research project, use either client:

```sh
claude mcp add --scope local --transport http openalex https://mcp.openalex.org/mcp
opencode mcp add openalex --url https://mcp.openalex.org/mcp
```

If prompted, authenticate in the browser via Claude Code’s `/mcp` or OpenCode’s
`/mcps`. Queries go to OpenAlex; use public search terms, not private data.
