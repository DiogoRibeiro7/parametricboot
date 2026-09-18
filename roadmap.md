# Roadmap

Status of the package. It is a work in progress: the current focus is on
maturing the methods and the interface (sections 2 to 4). A CRAN release is
deliberately deferred until the package is judged mature enough. See `NEWS.md`
for what changed in each version.

## 1. Project setup

- [x] R package skeleton, MIT licence (`MIT + file LICENSE`) and `DESCRIPTION`.

## 2. Core functionality

- [x] `pb_simulate()` – run N parametric bootstrap replicates, for `lm()`,
  `glm()`, `lme4::lmer()`, `lme4::glmer()` and `survival::coxph()` fits.
- [x] `pb_parallel()` – run the refits in parallel (base 'parallel' cluster),
  reproducibly.
- [x] `pb_drop_warned()` – exclude replicates whose refit raised a warning
  (for example separated logistic regressions).
- [x] `pb_key_stats()` – bias, standard error, MSE and Wald coverage.
- [x] `pb_confint()` – percentile, basic and normal intervals.
- [x] `pb_summary_table()`, `pb_tidy()`, and `print()`, `summary()` and
  `confint()` methods.
- [x] `pb_plot_estimates()`, `pb_plot_diagnostics()`, `pb_plot_predictions()`.
- [x] `pb_predict_boot()` – predictions with bootstrap uncertainty.
- [x] `pb_compare_models()` – bootstrap distribution of a fit criterion.
- [x] `pb_lrt()` and `pb_plot_lrt()` – bootstrap likelihood-ratio test for
  nested models, including variance components and `coxph` fits.
- [x] `pb_resample()` – case-resampling helper.

Ideas for later versions:

- [ ] Studentised (bootstrap-t) intervals, using the stored standard errors.
- [ ] Bootstrap distributions of variance components for mixed models.
- [ ] `coxph` models with `strata()`.
- [ ] A 'future' backend for `pb_parallel()` (clusters, progress reporting).
- [ ] 'broom'-style `tidy()` and `glance()` methods.

## 3. Package infrastructure

- [x] 'roxygen2' documentation with runnable examples.
- [x] Getting-started vignette.
- [x] 'testthat' suite covering every exported function and model class.
- [x] 'pkgdown' configuration.

## 4. Quality assurance

- [x] `R CMD check --as-cran` clean locally.
- [x] GitHub Actions: `R CMD check` on Linux, macOS and Windows; test
  coverage; 'pkgdown' site.
- [x] Coverage reported to Codecov, with a badge in the README.
- [x] 'pkgdown' site published with GitHub Pages at
  <https://diogoribeiro7.github.io/parametricboot/>.

## 5. Preparing for CRAN (deferred)

Not planned for now. To be picked up once the package is mature.

- [ ] Choose a release version (`0.1.0`) and finalise `NEWS.md`.
- [ ] Check on win-builder (`devtools::check_win_devel()`) and R-hub.
- [ ] Write `cran-comments.md`.
- [ ] Ensure all package metadata (title, description, authors, URLs) is
  complete.

## 6. Submitting to CRAN (deferred)

- [ ] `devtools::release()`.
- [ ] Respond to CRAN maintainers if revisions are requested.
- [ ] Once accepted, tag the release in Git and announce availability.

## 7. Maintenance

- [ ] Monitor issues and update the package as needed.
- [ ] Follow semantic versioning once there is a first release.
