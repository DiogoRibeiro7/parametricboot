# Repeated-sampling coverage under a known Gaussian model

Run from a locally installed development version of `parametricboot`:

```sh
Rscript inst/validation/gaussian-coverage.R
OUTER_N=400 BOOT_N=999 Rscript inst/validation/gaussian-coverage.R
```

The script fixes a full-rank design matrix, a known coefficient vector, and
a known Gaussian error standard deviation. It repeatedly generates a fresh
dataset, refits ordinary least squares, and checks whether three intervals
contain the *true* slope:

- The analytical Student t interval (exact coverage under the assumptions).
- The parametric bootstrap percentile interval.
- The parametric bootstrap studentised interval.

For each newly generated dataset, a new inner bootstrap is run. This is
essential: a single parametric bootstrap on a single fitted dataset estimates
a conditional distribution, not repeated-sampling coverage.

The output reports empirical coverage and its binomial plug-in Monte Carlo
standard error over independent outer repetitions. The inner bootstrap has
its own quantile Monte Carlo error, which is *not* included in the reported
outer standard error. Neither quantity measures model misspecification.

Default settings (80 outer experiments, 199 bootstrap refits per dataset)
are illustrative and can produce noisy estimates. Increase both budgets
before using results in a report. Running the script does not modify any
package API, submit to CRAN, or assert that bootstrap intervals always attain
nominal coverage.
