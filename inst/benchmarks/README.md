# Benchmarking bootstrap prediction memory

This benchmark compares **retained refitted models** with **cached predictions**
for the same Gaussian linear model and identical bootstrap random seed.

Run locally after installing the development version of `parametricboot`:

```sh
Rscript inst/benchmarks/prediction-memory.R
```

The script constructs 2,000 observations and 60 bootstrap replicates. It
requests predictions at 12 fixed covariate values. The two modes are:

- `keep_fits = TRUE`: retain refitted model objects and predictions.
- `keep_fits = FALSE`: retain cached predictions without refitted models.

It checks that both prediction matrices agree and that failure flags match
before reporting `object.size()` in MiB and elapsed runtime. Numbers are
**intentionally not hard-coded**: they depend on platform, R version and
implementation, and are not a promise of a specific speed-up.

## How to interpret the measurements

`object.size()` measures the returned R objects rather than peak memory
usage or temporary allocations during fitting. It does not measure
overall process RSS, memory copied by parallel workers or all shared
references to the source dataset. Elapsed time is a single informal
measurement and should not be interpreted as a statistically robust
performance comparison.

Choose `keep_fits = FALSE` for analysis that needs predictions on the
**same fixed `newdata` and `predict_args`** used during simulation.
Retain refits when arbitrary new predictions, future-observation simulation,
or model-dependent diagnostics are required. In particular,
`pb_predict_interval()` and `pb_predict_variance()` require refits.

For a publication-quality performance study, vary training sizes,
replicate counts and model families, measure peak RSS separately, use
multiple repetitions, and report R version and hardware.
