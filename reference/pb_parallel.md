# Run parametric bootstrap replicates in parallel

A drop-in replacement for [`pb_simulate()`](pb_simulate.md) that
distributes the model refits over a local cluster of R processes.

## Usage

``` r
pb_parallel(model, n = 100, workers = 2, ..., seed = NULL, keep_fits = TRUE)
```

## Arguments

- model:

  A fitted model from [`stats::lm()`](https://rdrr.io/r/stats/lm.html),
  [`stats::glm()`](https://rdrr.io/r/stats/glm.html),
  [`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html),
  [`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html) or
  [`survival::coxph()`](https://rdrr.io/pkg/survival/man/coxph.html).

- n:

  Number of bootstrap replicates.

- workers:

  Number of parallel worker processes.

- ...:

  Additional arguments used when refitting: they override arguments of
  the original call for `lm`, `glm` and `coxph` models, and are passed
  to [`lme4::refit()`](https://rdrr.io/pkg/lme4/man/refit.html) for
  mixed models.

- seed:

  Optional single number. If supplied, the replicates are reproducible
  and the state of the global random number generator is left untouched.

- keep_fits:

  Should the refitted models be stored? They are needed by
  [`pb_predict_boot()`](pb_predict_boot.md),
  [`pb_plot_predictions()`](pb_plot_predictions.md) and
  [`pb_compare_models()`](pb_compare_models.md), but can use a lot of
  memory for large `n`.

## Value

An object of class `pb_boot`; see [`pb_simulate()`](pb_simulate.md).

## Details

The bootstrap responses are simulated in the calling process and only
the refits are distributed, so for a given `seed` the result is
identical to that of [`pb_simulate()`](pb_simulate.md), whatever the
number of workers.

The workers are fresh R sessions: 'parametricboot' must be installed
(not just loaded with `devtools::load_all()`), and everything the model
call needs, such as weights or offsets, should be a column of `data`
rather than a variable in the global environment.

Parallel execution has a start-up cost, so it only pays off when a
single refit is slow, as is typical for mixed models.

## Examples

``` r
# \donttest{
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
res <- pb_parallel(fit, n = 50, workers = 2, seed = 1)
#> Warning: 1 of 50 bootstrap refits produced warnings (for example convergence problems).
res
#> <pb_boot> Parametric bootstrap
#>   Model:      glm (binomial)
#>   Replicates: 50 (1 with warnings)
#>   Terms:      (Intercept), mpg
# }
```
