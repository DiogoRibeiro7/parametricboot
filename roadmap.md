# Roadmap

parametricboot is a work in progress. This page says where it stands,
what comes next and why, and what it deliberately does not do. It is a
statement of intent, not a schedule: priorities will move as the package
is used on real analyses. `NEWS.md` records what has changed.

To influence the roadmap, open an
[issue](https://github.com/DiogoRibeiro7/parametricboot/issues)
describing the analysis you are trying to carry out.

## Principles

These have shaped the package so far and decide what gets in.

1.  **Every method is validated against something independent**: an
    exact result or a reference implementation. The validation is kept
    as a test.
2.  **Never silently wrong.** A model that cannot be bootstrapped
    correctly is rejected with the reason, rather than bootstrapped
    approximately.
3.  **One engine.** Replicates are reproducible from a seed and
    identical whether they run sequentially or in parallel.
4.  **Few hard dependencies.** Model packages belong in `Suggests`.

## Where it stands

| Capability | Functions | Validated against |
|----|----|----|
| Replicates for `lm`, `glm`, `lmer`, `glmer`, `coxph` (with `strata()`) | [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md), [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md) | theoretical standard errors; [`lme4::bootMer()`](https://rdrr.io/pkg/lme4/man/bootMer.html), replicate for replicate; `survfit()` cumulative hazards |
| Bias, standard error, MSE, Wald coverage | [`pb_key_stats()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_key_stats.md), [`pb_summary_table()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_summary_table.md) | hand computation |
| Percentile, basic, normal and studentised intervals | [`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md), [`confint()`](https://rdrr.io/r/stats/confint.html) | the exact t interval of the normal linear model |
| Variance components of mixed models | all summaries | [`lme4::bootMer()`](https://rdrr.io/pkg/lme4/man/bootMer.html) |
| Likelihood-ratio test for nested models | [`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md), [`pb_plot_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_lrt.md) | the exact F test; [`anova()`](https://rdrr.io/r/stats/anova.html) |
| Predictions with bootstrap uncertainty | [`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md), [`pb_plot_predictions()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_predictions.md) | [`predict()`](https://rdrr.io/r/stats/predict.html) on the refits |
| Degenerate refits (for example separation) | [`pb_drop_warned()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_drop_warned.md) |  |
| Comparing models that are not nested | [`pb_compare_models()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_compare_models.md) |  |

Infrastructure: `R CMD check` on Linux, macOS and Windows, about 98%
test coverage, a [documentation
site](https://diogoribeiro7.github.io/parametricboot/) and contribution
guidelines.

## Now

The gaps most likely to be hit in a first real analysis.

### 1. Bootstrap any function of the fitted model

Only coefficients (and variance components) are tracked. The quantity of
interest is often something else: the LD50 of a dose-response curve
(`-b0 / b1`), an odds ratio, an intraclass correlation, a difference
between two predictions. Today that means looping over `res$replicates`
by hand.

- Proposal: a `statistic = function(fit)` argument in
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  returning a named numeric vector, tracked like a coefficient so that
  every summary, interval and plot works unchanged.
- Done when the LD50 of the budworm example has a bootstrap interval in
  the vignette, and a linear combination of `lm` coefficients reproduces
  its exact t interval.

### 2. Report Monte Carlo error

Nothing tells the user whether `n` was large enough. The only guidance
is a rule of thumb in the vignette and the running-mean plot.

- Proposal: Monte Carlo standard errors for the bias, the standard error
  and the interval limits in
  [`pb_key_stats()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_key_stats.md)
  and
  [`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md),
  and for the p-value of
  [`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md).
- Done when the advice on `n` in the documentation is backed by these
  numbers.

### 3. Make predictions affordable in memory

`keep_fits = TRUE` is the default and is needed for predictions, but
refits are heavy: 200 refits of a `glm` on 32 rows take 42 MB, and 50
refits on 20 000 rows take 560 MB.

- Proposal: compute predictions while simulating (a `newdata` argument),
  or store stripped-down refits, and then reconsider the default.
- Done when predictions are available without keeping the refits and the
  memory cost is documented.

### 4. Settle which model classes are accepted

Any class inheriting from `lm` or `glm` passes the input check.
[`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html) and
[`mgcv::gam()`](https://rdrr.io/pkg/mgcv/man/gam.html) fits run, but
nothing validates them. This is at odds with principle 2.

- `glm.nb` is a genuine parametric model: validate it and add tests.
- `gam` needs a decision, because refits re-estimate the smoothing
  parameters: either validate against `mgcv`’s own intervals or reject.
- Done when every accepted class has tests and all others are rejected
  with an explanation.

### 5. Interface review after first real use

Before anything is frozen, the package should be run on real analyses.
Known candidates for change:

- [`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md)
  has a redundant suffix; `pb_predict()` would match the other names.
- [`pb_key_stats()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_key_stats.md)
  and
  [`pb_summary_table()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_summary_table.md)
  overlap; one may be enough.
- The first argument is `results` in most functions but `test` in
  [`pb_plot_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_lrt.md);
  coefficients are selected with `parameter`, where `terms` would match
  the `term` column of the outputs.
- `n = 100` is a low default for confidence limits.

## Next

### 6. An extension interface for new model classes

Simulating a response and refitting the model are two internal functions
with one branch per class. Exporting them as generics would let users
and other packages add classes without changing this one, with an
article on how to do it. Intended first clients:

- [`survival::survreg()`](https://rdrr.io/pkg/survival/man/survreg.html):
  a fully parametric survival model, the most natural target for a
  parametric bootstrap and the complement of the Cox support;
- `glmmTMB`, `ordinal::clm()` /
  [`MASS::polr()`](https://rdrr.io/pkg/MASS/man/polr.html),
  [`nls()`](https://rdrr.io/r/stats/nls.html), `betareg`.

### 7. Prediction intervals for new observations

[`pb_plot_predictions()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_predictions.md)
gives intervals for the *expected* response. Intervals for a *new
observation* must add the response noise, by simulating from each refit.

### 8. Goodness of fit by simulation

The bootstrap null distribution of the deviance, the Pearson statistic,
the dispersion or the number of zeros, from the engine that
[`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md)
already uses. This matters most for sparse binomial and count data,
where the chi-squared approximation to the deviance fails.

### 9. Conditional bootstrap for mixed models

Replicates draw new random effects (a marginal bootstrap, as `bootMer()`
does by default). Holding the estimated random effects fixed
(`use.u = TRUE`) answers a different question: inference for the groups
actually observed. Passing `use.u` through `...` does not do this today,
because `...` goes to the refit and not to the simulation.

### 10. Ergonomics

- A ‘future’ backend for parallel execution, with progress reporting.
- ‘broom’-style `tidy()` and `glance()` methods.
- Classed conditions, so that calling code can react to “unsupported
  model” or “all refits failed” without matching on message text.

## Later

Worth doing, but each needs a design decision or is expensive.

- **Better intervals**: bootstrap calibration (double bootstrap) and
  BCa.
- **Separation-aware refits**: detect separated replicates explicitly
  (as ‘detectseparation’ does) instead of relying on warnings, and offer
  bias-reduced refits (as ‘brglm2’ does) as an alternative to dropping
  them.
- **More of the Cox model**: counting-process data with time-varying
  covariates, left truncation, case weights, and censoring that depends
  on covariates.
- **Power and sample size**: simulate from the alternative instead of
  the null and report rejection rates.
- **Speed**: a [`glm.fit()`](https://rdrr.io/r/stats/glm.html) fast path
  that skips re-evaluating the call, and a benchmark suite against
  ‘boot’, ‘pbkrtest’ and
  [`lme4::bootMer()`](https://rdrr.io/pkg/lme4/man/bootMer.html).

## Documentation

- An article, “How the package is validated”, collecting the exact
  benchmarks that are currently scattered over the tests: the F test,
  the t interval, `bootMer()` and the cumulative-hazard identity.
- Case studies: a small-sample logistic regression, a mixed model with
  few groups, a survival analysis.
- Snapshot tests for the [`print()`](https://rdrr.io/r/base/print.html)
  methods and visual tests for the plots.

## Known limitations

Things the current version does not do, so that nobody has to find out
the hard way.

- Models must be fitted with a `data` argument.
- Covariates are held fixed, and the fitted model is assumed to be
  correct: the bootstrap quantifies sampling variability under the model
  and does not detect misspecification.
- Quasi-likelihood families are not supported, by design: there is no
  likelihood to simulate from.
- Cox models: right-censored data only; no case weights, `tt()`,
  `frailty()`, penalised terms, `cluster()` or strata-by-covariate
  interactions. Censoring is assumed independent of the covariates
  within each stratum.
- Mixed models: marginal bootstrap only (see item 9). ‘lme4’ gives no
  standard errors for variance components, so their Wald coverage and
  studentised limits are `NA`.
- A warning is the only signal of a degenerate refit, and replicates are
  never dropped automatically; see
  [`pb_drop_warned()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_drop_warned.md).
- Keeping the refits is expensive in memory (see item 3).
- Parallel workers are fresh R sessions: the package must be installed,
  and everything the model call needs should be a column of `data`.

## Not planned

- A general nonparametric bootstrap. ‘boot’ and ‘rsample’ do this well;
  [`pb_resample()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_resample.md)
  exists only as a point of comparison.
- Bayesian posterior simulation.

## Versions and releases

The package stays at a development version while the interface can still
change. There is no CRAN submission planned. That will be reconsidered
by the maintainer when, at least:

- the “Now” items are done and the interface has survived use on real
  analyses without breaking changes for a few months;
- every accepted model class is validated and tested;
- there are no open correctness issues;
- `R CMD check --as-cran` is clean on all platforms, as it is today.

Tagging versions on GitHub does not depend on CRAN and would let users
pin a version. A first tag, `0.1.0`, makes sense once the “Now” items
are done.
