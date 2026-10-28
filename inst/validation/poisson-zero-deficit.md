# Calibration of the lower-tail Poisson zero-count test

Run this opt-in experiment with a locally installed development version of
`parametricboot`:

```sh
Rscript inst/validation/poisson-zero-deficit.R
OUTER_N=400 BOOT_N=999 Rscript inst/validation/poisson-zero-deficit.R
```

Two fixed-design mechanisms are compared: correctly specified Poisson
regression and independent positive-count draws from a zero-truncated Poisson
law. Both are fitted with an ordinary Poisson GLM. A fresh parametric
bootstrap measures the lower tail of the zero-count statistic for each outer
dataset.

The null rejection rate measures empirical type-I error. The rejection rate
under zero truncation measures power against this particular misspecification.
A zero-truncated process is not a Poisson process and is expected to contain
fewer zeros than an ordinary Poisson law.

The script reports method-specific evaluability, mean successful refits,
rejection rates and plug-in outer Monte Carlo standard errors. The inner
bootstrap introduces additional resolution limits; neither these estimates
nor their error bars prove uniform calibration. The finite defaults are
illustrative rather than acceptance thresholds.

This complements `poisson-gof-calibration.R`, which tests excess zeros with
the *upper* tail under a structurally zero-inflated alternative.
