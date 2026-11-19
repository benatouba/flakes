---
name: climate-model-evaluation
description: Plan climate model diagnostics, reference datasets, and fair model comparisons.
disable-model-invocation: true
---

# Climate model evaluation

Local planning skill grounded in primary sources; not independently validated.
Use available metadata and project tooling. Deliver a plan, not a job submission
or dataset download.

1. **Define the question.** Specify the process, variable, metric, region,
   timescale, experiments and comparison period. Identify whether the comparison
   targets a climatology, variability, trend, or response to forcing. Select a
   baseline and explain what would count as a meaningful difference.
2. **Match the reference.** Compare coverage, sampling, masks, calendar, grid,
   units and variable definitions. Document reference uncertainty and whether
   inputs are independent. Justify temporal aggregation, missing-data treatment
   and whether to compare on native grids or a justified common grid.
3. **Select diagnostics.** Look for a matching ESMValTool recipe or PCMDI Metrics
   Package metric in the installed tool version. Record preprocessing, weighting,
   diagnostic settings, required metadata and sensitivity checks. Separate
   within-model variability from between-model spread; explain member weighting
   and limitations from short records or shared model lineage.
4. **Hand off.** Return a table of question, inputs, preprocessing, metrics,
   uncertainty checks and expected artifacts. Specify a small validation case
   and record deviations from the reference recipe. Mark assumptions to resolve
   before the full run.

References: [ESMValTool recipes](https://docs.esmvaltool.org/en/stable/recipes/index.html),
[ESMValCore](https://docs.esmvaltool.org/projects/esmvalcore/en/stable/), and
[PCMDI Metrics Package](https://pcmdi.github.io/pcmdi_metrics/).
