# parametricboot 0.0.0.9000

## Memory-efficient bootstrap predictions

* Add optional `newdata` and `predict_args` to `pb_simulate()` and `pb_parallel()` to cache predictions as each model is refitted, independently of `keep_fits`.
* Reuse cached predictions through `pb_predict_boot()` with strict request matching; mismatched requests require retained models. Prediction failures do not silently discard valid model parameter estimates.

## Studentised intervals for custom statistics\n\n* Add an optional `statistic_se(fit)` callback with strictly positive, finite,\n  aligned standard errors for the original model and successful refits.\n* Permit bootstrap-t intervals and their Monte Carlo rank bounds for custom\n  statistics when justified standard errors are supplied. Keep the default\n  coefficient and non-studentised behaviour unchanged.\n\n## Custom bootstrap statistics

* Add a `statistic = function(fit)` argument to `pb_simulate()` and
  `pb_parallel()`. A stable named numeric result is tracked across refits,
  allowing inference for derived effects without storing fitted models.
* Preserve default coefficient behaviour and existing summaries, plots and
  Monte Carlo diagnostics. Studentised derived-statistic intervals are
  explicitly unsupported until analytic standard errors can be supplied.

## Monte Carlo precision of bootstrap summaries

* Add `pb_mc_error()` reporting conditional simulation error in bootstrap
  bias and standard deviation, based on finite successful refits and a
  first-order fourth-moment estimate where supported.
* Add `pb_confint_mc_error()` with exact binomial rank-based precision bounds
  for percentile, basic, and studentised interval endpoints. Unbounded
  limits indicate insufficient replicates for finite tail-quantile bounds.
* Keep `pb_confint()` and `pb_key_stats()` outputs unchanged, and distinguish
  simulation precision from model uncertainty and selective refit failures.

## Monte Carlo uncertainty

* Add `pb_lrt_mc_error()` for a standard error and exact binomial interval
  for the estimated bootstrap tail probability, conditional on valid refits.
  The existing add-one corrected p-value and `pb_lrt()` output are unchanged.
* Report the number of valid and failed refits; document the zero-exceedance
  case and distinguish simulation uncertainty from statistical/model uncertainty.

## Structured input validation

* Shared argument guards now return native R `dataexcept` ValidationError
  conditions with a `parametricboot_validation_error` subclass. Existing
  input error messages are preserved, and unchanged invalid inputs are marked
  permanent/non-retryable.
* Numerical bootstrap procedures, failed-refit aggregation, and operational
  errors are unchanged; add targeted regression tests for error metadata and
  machine-readable envelopes.
* Pin the native R dependency to an exact public GitHub source revision.

## Cox models

* `coxph()` models with `strata()` are now supported, in `pb_simulate()` and
  in `pb_lrt()`. Each stratum is resampled with its own baseline hazard,
  censoring distribution and end of follow-up. Results for unstratified
  models are unchanged.
* Models with `cluster()` are now rejected. They used to be accepted and
  resampled as if the observations were independent, which ignores the
  clustering. Strata-by-covariate interactions, for which there is no single
  baseline hazard per stratum, are rejected as well.

## Mixed models

* For `lmer()` and `glmer()` fits, the variance components are now tracked
  alongside the fixed effects: random-effect standard deviations and
  correlations and, where the family has one, the residual standard deviation.
  They are named as in `confint(model, oldNames = FALSE)`, for example
  `sd_(Intercept)|Subject` and `sigma`, and appear in every summary and plot.
  'lme4' provides no standard errors for them, so their Wald `coverage` and
  studentised limits are `NA`.
* Replicates are identical to those of `lme4::bootMer()` for the same seed,
  which is now tested.

## Confidence intervals

* `pb_confint()`, `pb_summary_table()` and `confint()` gain
  `type = "student"`, the studentised (bootstrap-t) interval, which scales
  each replicate by its own standard error. It reproduces the exact t interval
  for normal linear models and is insensitive to degenerate refits such as
  perfectly separated logistic regressions.

## Likelihood-ratio tests

* New `pb_lrt()`: parametric bootstrap likelihood-ratio test for nested
  models. It reports the asymptotic chi-squared, Bartlett-corrected and
  bootstrap p-values, works for every supported model class, accepts models
  of different classes (for example `lm()` against `lmer()` to test a variance
  component), refits REML fits by maximum likelihood, and can run in parallel.
  For normal linear models the bootstrap p-value converges to that of the
  exact F test.
* New `pb_plot_lrt()` compares the bootstrap null distribution of the
  statistic with the chi-squared approximation.
* Messages emitted while refitting, such as the "boundary (singular) fit" note
  of 'lme4', are no longer repeated for every replicate.

## Bootstrap engine

* `pb_simulate()` has been rewritten. The previous implementation could not
  refit any model: inside `replicate()`, `...` referred to the replicate
  counter, which was passed to `update()` as a formula.
* Models are refitted from the original data rather than from the model frame,
  so formulas with transformed terms (`log(x)`, `poly(x, 2)`), `offset()`,
  `weights`, `subset`, `y ~ .` and two-column binomial responses work, as do
  fits where rows were dropped because of missing values.
* `lm()` and `lme4::lmer()` models are now supported alongside `glm()` and
  `lme4::glmer()`. Mixed models are refitted with `lme4::refit()` and
  summarised on their fixed effects.
* `survival::coxph()` models, for which no `simulate()` method exists, are
  bootstrapped with the model-based resampling algorithm of Davison and
  Hinkley (1997, Algorithm 7.3). Stratified, weighted, penalised and
  counting-process models are rejected with an informative error.
* New `seed` argument for reproducible results that leave the global random
  number generator untouched, and `keep_fits` argument to store only the
  estimates.
* Refits that fail are dropped and refits that raise warnings are counted;
  each is reported in a single warning instead of aborting or flooding the
  console.
* New `pb_drop_warned()` excludes the replicates whose refit raised a warning,
  for example the perfectly separated data sets that small logistic
  regressions generate, whose arbitrary huge coefficients would otherwise ruin
  bootstrap means and standard errors.
* `pb_parallel()` shares the engine of `pb_simulate()` and returns identical
  results for a given `seed`. It validates the model, defaults to 2 workers
  instead of all cores, and checks that the workers can load the package.

## Summaries

* `pb_key_stats()` gains `estimate`, `boot_mean` and `std_error` columns.
  `coverage` is now the estimated coverage of the Wald interval (it used to be
  a logical flag that was `TRUE` by construction). New `level` argument.
* `pb_confint()` gains `type = c("percentile", "basic", "normal")` and an
  `estimate` column.
* `pb_summary_table()` keeps the coefficients in model order and gains `level`
  and `type` arguments.
* `pb_tidy()` returns a base data frame; the 'tidyr' dependency is gone.
* `pb_compare_models()` now evaluates `metric` on the bootstrap refits and
  reports its mean, standard deviation and percentile interval (it used to
  bootstrap each model and then discard the replicates). Models can be named.
* New `print()`, `summary()` and `confint()` methods for `pb_boot` objects.

## Plots

* `pb_plot_estimates()` draws histograms with the original estimate marked
  (it used to overlay a kernel density of a single point), and
  `pb_plot_diagnostics()` adds the running mean. In both, `parameter` is now
  optional and defaults to all coefficients.
* `pb_plot_predictions()` shows the predictions for each row of `newdata` with
  bootstrap percentile intervals, instead of one pooled density. The
  `parameter` argument is replaced by `x`, and `level` is new.
* `pb_predict_boot()` passes `...` to `predict()` and always returns a matrix.

## Infrastructure

* 'lme4' and 'survival' moved from `Imports` to `Suggests`.
* `NAMESPACE` and the Rd files are generated by 'roxygen2'; every function has
  runnable examples.
* 'testthat' >= 3.1.5 is now required to run the tests.
* Added a 'testthat' suite (the `tests` directory used to be excluded from the
  build), a vignette, a `CITATION` file, 'pkgdown' configuration and GitHub
  Actions workflows for `R CMD check`, test coverage and the website.
* The documentation website is <https://diogoribeiro7.github.io/parametricboot/>.
* The licence is declared as `MIT + file LICENSE`, as CRAN requires.
