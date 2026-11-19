---
name: scientific-reproducibility
description: "Record and verify how a scientific result was produced. Use when running an analysis that yields a figure, table or derived dataset, rebuilding a result, or preparing a computational methods handoff."
---

# Scientific reproducibility

Keep the rerun instructions and evidence in the project, independent of chat,
an agent's context index or a live notebook kernel.

1. **Define the run.** Find the project's existing workflow and provenance
   conventions. Give the analysis a version-controlled entry point, with explicit
   parameters, read-only inputs and a separate output location. For NetCDF,
   record the selected variables, coordinate bounds, units/calendar assumptions,
   missing-data treatment, and chunking or backend choices that affect the run.
   Subset and aggregate locally rather than printing raw arrays.
2. **Capture what ran.** Use the project's existing run record format, or write
   `runs/<run-id>/manifest.json` with one ID per attempt. Use evidence from the
   execution, not commands or parameters merely discussed in chat. Record:
   - UTC start/end, status and exit code; exact rerun command and working directory.
   - Code revision and dirty status, and how to recover any uncommitted changes.
     Record the lockfile revision/digest or pinned environment and relevant runtime versions.
   - Input versions or checksums, selections, actual parameters and seeds.
     Reuse trusted version identifiers or checksums for very large inputs; if an
     input is not immutably identified, mark that limitation explicitly.
   - Outputs and their locations, useful output checksums, and a reference to
     redacted logs if kept. Do not mark partial outputs from a failed run as valid.
   - Validation checks and results, including any tolerances or known nondeterminism.
3. **Verify the rerun.** Use a fresh process, a clean output directory, and the
   recorded environment. Choose a small representative fixture when a full
   rerun is expensive. Check scientific invariants such as dimensions, units,
   coverage and numeric agreement; use byte equality only when warranted.
   Record separately what was verified on the fixture and what was verified on
   the full dataset. Mark any check not run as unverified.

Keep manifests small. Reference inputs and artifacts rather than copying them
into the repository. Exclude credentials and private data from records and logs;
use project-relative paths or redacted dataset identifiers where appropriate.
