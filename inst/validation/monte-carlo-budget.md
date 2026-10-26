# Choosing a bootstrap replicate budget

A fixed number of bootstrap replicates is not universally adequate. Precision
depends on the estimand, tail probability, variability of the bootstrap
distribution and the number of successful refits.

## Bias and standard error

For a fitted model, start with a pilot bootstrap and inspect the Monte Carlo
diagnostics:

```r
library(parametricboot)
fit <- stats::lm(mpg ~ wt + hp, data = mtcars)
boot <- pb_simulate(fit, n = 499, seed = 2026, keep_fits = FALSE)
precision <- pb_mc_error(boot)
precision[, c("term", "replicates", "bias_mc_se", "std_error_mc_se")]
```

These are Monte Carlo errors *conditional on the fitted model*. They do not
measure uncertainty in the original parameter estimator. Decide a tolerable
absolute precision in the original parameter's units. When pilot estimates
are stable and independent refits remain representative, multiplying the
replicate count by approximately four should halve the Monte Carlo standard
error. This scaling is an approximation, not a guarantee.

Avoid a fixed relative-error target when the estimated bias is near zero:
a relative tolerance then becomes ill-defined.

## Confidence interval endpoints

```r
limits <- pb_confint_mc_error(
  boot, level = 0.95, type = "percentile", mc_level = 0.95
)
limits[, c(
  "term", "replicates", "lower", "lower_mc_low", "lower_mc_high",
  "upper", "upper_mc_low", "upper_mc_high"
)]
```

The four `*_mc_*` columns bound the *simulation variability* of the
estimated interval endpoints, not statistical uncertainty about the true
coefficient. They are per-endpoint bounds, not simultaneous bands.

For a 95% percentile confidence interval, both endpoints use extreme
2.5% quantiles. Small bootstrap samples provide limited information about
those tails. Infinite Monte Carlo bounds correctly indicate insufficient
replicates to bracket the endpoint at the requested `mc_level`.
Increasing the replicate budget is preferable to discarding those bounds.

For `type = "normal"`, the endpoint bounds instead rely on a first-order
delta-method approximation, which can be unreliable for heavy tails or
degenerate variance estimates.

## Likelihood-ratio and goodness-of-fit p-values

```r
null <- stats::lm(mpg ~ wt, data = mtcars)
alternative <- stats::lm(mpg ~ wt + hp, data = mtcars)
test <- pb_lrt(null, alternative, n = 999, seed = 2026)
pb_lrt_mc_error(test)
```

The bootstrap LRT p-value cannot be less than `1 / (B + 1)` for `B`
valid replicates. To resolve a p-value below a target alpha at all,
one needs `1 / (B + 1) < alpha`; that necessary condition is not
sufficient for a *precise* estimate near alpha. The exact binomial bounds
describe the underlying tail probability, whereas the reported bootstrap
p-value uses the add-one correction.

The same distinction applies to `pb_gof_mc_error()`: it reports conditional
Monte Carlo precision for the raw tail probability, separately from the
add-one-corrected p-value.

## Failure and stopping rules

A large fraction of failed or warned refits may indicate a statistical or
numerical problem. More replicates do not fix biased exclusion of failed
refits. Report successful, failed and warned counts alongside precision
diagnostics.

Choose a replicate budget before interpreting evidence near a decision
threshold. Iteratively increasing `n` after seeing an appealing p-value,
then stopping when significant, is an optional-stopping procedure and should
not be presented as a fixed-budget test with nominal guarantees. If a
sequential stopping rule is required, develop and validate that rule
separately.

A running-mean diagnostic is useful for identifying gross instability, but
visual stability is not a substitute for numerical Monte Carlo precision.
