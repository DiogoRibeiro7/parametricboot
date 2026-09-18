# Roadmap

Status of the path from prototype to a CRAN release. See `NEWS.md` for
what changed in each version.

## 1. Project setup

R package skeleton, MIT licence (`MIT + file LICENSE`) and
`DESCRIPTION`.

## 2. Core functionality

[`pb_simulate()`](reference/pb_simulate.md) – run N parametric bootstrap
replicates, for [`lm()`](https://rdrr.io/r/stats/lm.html),
[`glm()`](https://rdrr.io/r/stats/glm.html),
[`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html),
[`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html) and
[`survival::coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) fits.

[`pb_parallel()`](reference/pb_parallel.md) – run the refits in parallel
(base ‘parallel’ cluster), reproducibly.

[`pb_drop_warned()`](reference/pb_drop_warned.md) – exclude replicates
whose refit raised a warning (for example separated logistic
regressions).

[`pb_key_stats()`](reference/pb_key_stats.md) – bias, standard error,
MSE and Wald coverage.

[`pb_confint()`](reference/pb_confint.md) – percentile, basic and normal
intervals.

[`pb_summary_table()`](reference/pb_summary_table.md),
[`pb_tidy()`](reference/pb_tidy.md), and
[`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`confint()`](https://rdrr.io/r/stats/confint.html) methods.

[`pb_plot_estimates()`](reference/pb_plot_estimates.md),
[`pb_plot_diagnostics()`](reference/pb_plot_diagnostics.md),
[`pb_plot_predictions()`](reference/pb_plot_predictions.md).

[`pb_predict_boot()`](reference/pb_predict_boot.md) – predictions with
bootstrap uncertainty.

[`pb_compare_models()`](reference/pb_compare_models.md) – bootstrap
distribution of a fit criterion.

[`pb_resample()`](reference/pb_resample.md) – case-resampling helper.

Ideas for later versions:

Studentised (bootstrap-t) intervals, using the stored standard errors.

Bootstrap likelihood-ratio test for nested models, as in
`pbkrtest::PBmodcomp()`.

Bootstrap distributions of variance components for mixed models.

`coxph` models with `strata()`.

A ‘future’ backend for [`pb_parallel()`](reference/pb_parallel.md)
(clusters, progress reporting).

‘broom’-style `tidy()` and `glance()` methods.

## 3. Package infrastructure

‘roxygen2’ documentation with runnable examples.

Getting-started vignette.

‘testthat’ suite covering every exported function and model class.

‘pkgdown’ configuration.

## 4. Quality assurance

`R CMD check --as-cran` clean locally.

GitHub Actions: `R CMD check` on Linux, macOS and Windows; test
coverage; ‘pkgdown’ site.

Add the `CODECOV_TOKEN` secret and a coverage badge.

Enable GitHub Pages (branch `gh-pages`), then add the site address as
`url:` in `_pkgdown.yml` and to `URL` in `DESCRIPTION`.

## 5. Preparing for CRAN

Choose a release version (`0.1.0`) and finalise `NEWS.md`.

Check on win-builder (`devtools::check_win_devel()`) and R-hub.

Write `cran-comments.md`.

Ensure all package metadata (title, description, authors, URLs) is
complete.

## 6. Submitting to CRAN

`devtools::release()`.

Respond to CRAN maintainers if revisions are requested.

Once accepted, tag the release in Git and announce availability.

## 7. Post-release maintenance

Monitor issues and update the package as needed.

Follow semantic versioning for future releases.
