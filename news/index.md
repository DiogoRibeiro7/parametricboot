# Changelog

## parametricboot 0.0.0.9000

### Goodness-of-fit tail and uncertainty diagnostics

- Add `tail = "less"` to
  [`pb_gof()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_gof.md)
  for deficits of zeros and unusually small discrepancy statistics;
  retain the default `"greater"` behaviour.
- Add
  [`pb_gof_mc_error()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_gof_mc_error.md)
  with exact binomial confidence limits for the raw Monte Carlo tail
  probability, separate from the add-one p-value.
- Add
  [`pb_plot_gof()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_gof.md)
  to inspect the empirical reference distribution. Validate zero-count
  tails against the exact Poisson-to-binomial identity.

### Simulation-based goodness of fit

- Add
  [`pb_gof()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_gof.md)
  for deviance, Pearson and count-zero statistics using simulated
  responses, model refitting, and a finite-sample add-one p-value.
- Expose failed and warned refits, require validated model classes, and
  cover reference calculations with deterministic regression tests.

### Normal-interval Monte Carlo precision

- Support `pb_confint_mc_error(type = "normal")` via first-order
  influence functions for the sample mean and standard deviation,
  preserving covariance.
- Keep existing confidence interval endpoints unchanged. Return NA
  precision bounds when fewer than four finite estimates or zero spread
  prevent the approximation, and distinguish these limits from exact
  quantile rank bounds.

### Derived-statistic validation case studies

- Validate sex-specific median lethal doses in the budworm logistic
  model using named custom-statistic callbacks and percentile intervals.
- Independently benchmark studentised intervals for a linear combination
  of Gaussian regression coefficients against the exact Student t
  interval.
- Record Monte Carlo precision separately from statistical uncertainty;
  update the vignette and close roadmap item 1 for supported models.

### Validated negative-binomial regression support

- Admit the exact
  [`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html) class
  with its fitted negative-binomial simulator, re-estimating the
  dispersion parameter on every bootstrap refit. Validate the simulation
  moments against independent NB identities and refitted coefficients
  and dispersion against direct
  [`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html).
- Reject non-unit prior weights, malformed dispersion and unsupported
  Poisson-versus-negative-binomial likelihood-ratio comparisons; keep
  other unvalidated inherited model classes rejected.
- Add `MASS` as an optional model package, with deterministic and
  guarded regression tests.

### Fail-closed model-class contract

- Accept the canonical base-R `lm` and `glm` S3 classes for the
  linear-model bootstrap path, rather than every unvalidated subclass.
- Reject `gam`, `aov` and other inherited, unvalidated fits with a
  structured, non-retryable validation error until they are
  independently tested. Reject quasi-likelihood GLM families because
  they do not specify a parametric response distribution.
- Preserve supported `lme4`, `coxph`, standard `lm` and `glm`
  calculations, and apply the same guard to bootstrap LRTs.

### Memory-efficient bootstrap predictions

- Add optional `newdata` and `predict_args` to
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  and
  [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md)
  to cache predictions as each model is refitted, independently of
  `keep_fits`.
- Reuse cached predictions through
  [`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md)
  with strict request matching; mismatched requests require retained
  models. Prediction failures do not silently discard valid model
  parameter estimates.

### Studentised intervals for custom statistics

- Add an optional `statistic_se(fit)` callback with strictly positive,
  finite, aligned standard errors for the original model and successful
  refits.
- Permit bootstrap-t intervals and their Monte Carlo rank bounds for
  custom statistics when justified standard errors are supplied. Keep
  the default coefficient and non-studentised behaviour unchanged.

### Custom bootstrap statistics

- Add a `statistic = function(fit)` argument to
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  and
  [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md).
  A stable named numeric result is tracked across refits, allowing
  inference for derived effects without storing fitted models.
- Preserve default coefficient behaviour and existing summaries, plots
  and Monte Carlo diagnostics. Studentised derived-statistic intervals
  are explicitly unsupported until analytic standard errors can be
  supplied.

### Monte Carlo precision of bootstrap summaries

- Add
  [`pb_mc_error()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_mc_error.md)
  reporting conditional simulation error in bootstrap bias and standard
  deviation, based on finite successful refits and a first-order
  fourth-moment estimate where supported.
- Add
  [`pb_confint_mc_error()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint_mc_error.md)
  with exact binomial rank-based precision bounds for percentile, basic,
  and studentised interval endpoints. Unbounded limits indicate
  insufficient replicates for finite tail-quantile bounds.
- Keep
  [`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md)
  and
  [`pb_key_stats()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_key_stats.md)
  outputs unchanged, and distinguish simulation precision from model
  uncertainty and selective refit failures.

### Monte Carlo uncertainty

- Add
  [`pb_lrt_mc_error()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt_mc_error.md)
  for a standard error and exact binomial interval for the estimated
  bootstrap tail probability, conditional on valid refits. The existing
  add-one corrected p-value and
  [`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md)
  output are unchanged.
- Report the number of valid and failed refits; document the
  zero-exceedance case and distinguish simulation uncertainty from
  statistical/model uncertainty.

### Structured input validation

- Shared argument guards now return native R `dataexcept`
  ValidationError conditions with a `parametricboot_validation_error`
  subclass. Existing input error messages are preserved, and unchanged
  invalid inputs are marked permanent/non-retryable.
- Numerical bootstrap procedures, failed-refit aggregation, and
  operational errors are unchanged; add targeted regression tests for
  error metadata and machine-readable envelopes.
- Pin the native R dependency to an exact public GitHub source revision.

### Cox models

- [`coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) models with
  [`strata()`](https://rdrr.io/pkg/survival/man/strata.html) are now
  supported, in
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  and in
  [`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md).
  Each stratum is resampled with its own baseline hazard, censoring
  distribution and end of follow-up. Results for unstratified models are
  unchanged.
- Models with
  [`cluster()`](https://rdrr.io/pkg/survival/man/cluster.html) are now
  rejected. They used to be accepted and resampled as if the
  observations were independent, which ignores the clustering.
  Strata-by-covariate interactions, for which there is no single
  baseline hazard per stratum, are rejected as well.

### Mixed models

- For `lmer()` and `glmer()` fits, the variance components are now
  tracked alongside the fixed effects: random-effect standard deviations
  and correlations and, where the family has one, the residual standard
  deviation. They are named as in `confint(model, oldNames = FALSE)`,
  for example `sd_(Intercept)|Subject` and `sigma`, and appear in every
  summary and plot. ‘lme4’ provides no standard errors for them, so
  their Wald `coverage` and studentised limits are `NA`.
- Replicates are identical to those of
  [`lme4::bootMer()`](https://rdrr.io/pkg/lme4/man/bootMer.html) for the
  same seed, which is now tested.

### Confidence intervals

- [`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md),
  [`pb_summary_table()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_summary_table.md)
  and [`confint()`](https://rdrr.io/r/stats/confint.html) gain
  `type = "student"`, the studentised (bootstrap-t) interval, which
  scales each replicate by its own standard error. It reproduces the
  exact t interval for normal linear models and is insensitive to
  degenerate refits such as perfectly separated logistic regressions.

### Likelihood-ratio tests

- New
  [`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md):
  parametric bootstrap likelihood-ratio test for nested models. It
  reports the asymptotic chi-squared, Bartlett-corrected and bootstrap
  p-values, works for every supported model class, accepts models of
  different classes (for example
  [`lm()`](https://rdrr.io/r/stats/lm.html) against `lmer()` to test a
  variance component), refits REML fits by maximum likelihood, and can
  run in parallel. For normal linear models the bootstrap p-value
  converges to that of the exact F test.
- New
  [`pb_plot_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_lrt.md)
  compares the bootstrap null distribution of the statistic with the
  chi-squared approximation.
- Messages emitted while refitting, such as the “boundary (singular)
  fit” note of ‘lme4’, are no longer repeated for every replicate.

### Bootstrap engine

- [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  has been rewritten. The previous implementation could not refit any
  model: inside [`replicate()`](https://rdrr.io/r/base/lapply.html),
  `...` referred to the replicate counter, which was passed to
  [`update()`](https://rdrr.io/r/stats/update.html) as a formula.
- Models are refitted from the original data rather than from the model
  frame, so formulas with transformed terms (`log(x)`, `poly(x, 2)`),
  [`offset()`](https://rdrr.io/r/stats/offset.html), `weights`,
  `subset`, `y ~ .` and two-column binomial responses work, as do fits
  where rows were dropped because of missing values.
- [`lm()`](https://rdrr.io/r/stats/lm.html) and
  [`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html) models are
  now supported alongside [`glm()`](https://rdrr.io/r/stats/glm.html)
  and [`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html). Mixed
  models are refitted with
  [`lme4::refit()`](https://rdrr.io/pkg/lme4/man/refit.html) and
  summarised on their fixed effects.
- [`survival::coxph()`](https://rdrr.io/pkg/survival/man/coxph.html)
  models, for which no
  [`simulate()`](https://rdrr.io/r/stats/simulate.html) method exists,
  are bootstrapped with the model-based resampling algorithm of Davison
  and Hinkley (1997, Algorithm 7.3). Stratified, weighted, penalised and
  counting-process models are rejected with an informative error.
- New `seed` argument for reproducible results that leave the global
  random number generator untouched, and `keep_fits` argument to store
  only the estimates.
- Refits that fail are dropped and refits that raise warnings are
  counted; each is reported in a single warning instead of aborting or
  flooding the console.
- New
  [`pb_drop_warned()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_drop_warned.md)
  excludes the replicates whose refit raised a warning, for example the
  perfectly separated data sets that small logistic regressions
  generate, whose arbitrary huge coefficients would otherwise ruin
  bootstrap means and standard errors.
- [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md)
  shares the engine of
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  and returns identical results for a given `seed`. It validates the
  model, defaults to 2 workers instead of all cores, and checks that the
  workers can load the package.

### Summaries

- [`pb_key_stats()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_key_stats.md)
  gains `estimate`, `boot_mean` and `std_error` columns. `coverage` is
  now the estimated coverage of the Wald interval (it used to be a
  logical flag that was `TRUE` by construction). New `level` argument.
- [`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md)
  gains `type = c("percentile", "basic", "normal")` and an `estimate`
  column.
- [`pb_summary_table()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_summary_table.md)
  keeps the coefficients in model order and gains `level` and `type`
  arguments.
- [`pb_tidy()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_tidy.md)
  returns a base data frame; the ‘tidyr’ dependency is gone.
- [`pb_compare_models()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_compare_models.md)
  now evaluates `metric` on the bootstrap refits and reports its mean,
  standard deviation and percentile interval (it used to bootstrap each
  model and then discard the replicates). Models can be named.
- New [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html) and
  [`confint()`](https://rdrr.io/r/stats/confint.html) methods for
  `pb_boot` objects.

### Plots

- [`pb_plot_estimates()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_estimates.md)
  draws histograms with the original estimate marked (it used to overlay
  a kernel density of a single point), and
  [`pb_plot_diagnostics()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_diagnostics.md)
  adds the running mean. In both, `parameter` is now optional and
  defaults to all coefficients.
- [`pb_plot_predictions()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_predictions.md)
  shows the predictions for each row of `newdata` with bootstrap
  percentile intervals, instead of one pooled density. The `parameter`
  argument is replaced by `x`, and `level` is new.
- [`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md)
  passes `...` to [`predict()`](https://rdrr.io/r/stats/predict.html)
  and always returns a matrix.

### Infrastructure

- ‘lme4’ and ‘survival’ moved from `Imports` to `Suggests`.
- `NAMESPACE` and the Rd files are generated by ‘roxygen2’; every
  function has runnable examples.
- ‘testthat’ \>= 3.1.5 is now required to run the tests.
- Added a ‘testthat’ suite (the `tests` directory used to be excluded
  from the build), a vignette, a `CITATION` file, ‘pkgdown’
  configuration and GitHub Actions workflows for `R CMD check`, test
  coverage and the website.
- The documentation website is
  <https://diogoribeiro7.github.io/parametricboot/>.
- The licence is declared as `MIT + file LICENSE`, as CRAN requires.
