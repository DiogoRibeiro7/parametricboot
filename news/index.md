# Changelog

## parametricboot 0.0.0.9000

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
