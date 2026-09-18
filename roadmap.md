# Roadmap

Status of the package. It is a work in progress: the current focus is on
maturing the methods and the interface (sections 2 to 4). A CRAN release
is deliberately deferred until the package is judged mature enough. See
`NEWS.md` for what changed in each version.

## 1. Project setup

R package skeleton, MIT licence (`MIT + file LICENSE`) and
`DESCRIPTION`.

## 2. Core functionality

[`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
– run N parametric bootstrap replicates, for
[`lm()`](https://rdrr.io/r/stats/lm.html),
[`glm()`](https://rdrr.io/r/stats/glm.html),
[`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html),
[`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html) and
[`survival::coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) fits.

Stratified `coxph` models, resampled within strata.

[`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md)
– run the refits in parallel (base ‘parallel’ cluster), reproducibly.

[`pb_drop_warned()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_drop_warned.md)
– exclude replicates whose refit raised a warning (for example separated
logistic regressions).

[`pb_key_stats()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_key_stats.md)
– bias, standard error, MSE and Wald coverage.

[`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md)
– percentile, basic, normal and studentised intervals.

[`pb_summary_table()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_summary_table.md),
[`pb_tidy()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_tidy.md),
and [`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html) and
[`confint()`](https://rdrr.io/r/stats/confint.html) methods.

[`pb_plot_estimates()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_estimates.md),
[`pb_plot_diagnostics()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_diagnostics.md),
[`pb_plot_predictions()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_predictions.md).

[`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md)
– predictions with bootstrap uncertainty.

[`pb_compare_models()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_compare_models.md)
– bootstrap distribution of a fit criterion.

Variance components of mixed models tracked alongside the fixed effects.

[`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md)
and
[`pb_plot_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_lrt.md)
– bootstrap likelihood-ratio test for nested models, including variance
components and `coxph` fits.

[`pb_resample()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_resample.md)
– case-resampling helper.

Ideas for later versions:

A ‘future’ backend for
[`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md)
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

Coverage reported to Codecov, with a badge in the README.

‘pkgdown’ site published with GitHub Pages at
<https://diogoribeiro7.github.io/parametricboot/>.

## 5. Preparing for CRAN (deferred)

Not planned for now. To be picked up once the package is mature.

Choose a release version (`0.1.0`) and finalise `NEWS.md`.

Check on win-builder (`devtools::check_win_devel()`) and R-hub.

Write `cran-comments.md`.

Ensure all package metadata (title, description, authors, URLs) is
complete.

## 6. Submitting to CRAN (deferred)

`devtools::release()`.

Respond to CRAN maintainers if revisions are requested.

Once accepted, tag the release in Git and announce availability.

## 7. Maintenance

Monitor issues and update the package as needed.

Follow semantic versioning once there is a first release.
