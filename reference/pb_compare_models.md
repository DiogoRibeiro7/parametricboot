# Compare models by the bootstrap distribution of a fit metric

Runs a parametric bootstrap for each model and evaluates `metric` on the
original fit and on every refit. This shows how much a criterion such as
the AIC varies from sample to sample under each fitted model, which
helps to judge whether an observed difference between models is
meaningful.

## Usage

``` r
pb_compare_models(
  models,
  n = 100,
  metric = stats::AIC,
  level = 0.95,
  seed = NULL,
  ...
)
```

## Arguments

- models:

  A non-empty list of fitted models supported by
  [`pb_simulate()`](pb_simulate.md). Names, if present, are used to
  label the models.

- n:

  Number of bootstrap replicates for each model.

- metric:

  A function that takes a fitted model and returns a single number, such
  as [`stats::AIC()`](https://rdrr.io/r/stats/AIC.html),
  [`stats::BIC()`](https://rdrr.io/r/stats/AIC.html) or
  [`stats::deviance()`](https://rdrr.io/r/stats/deviance.html).

- level:

  Level of the percentile interval reported for the metric.

- seed:

  Optional single number making the comparison reproducible.

- ...:

  Additional arguments passed to [`pb_simulate()`](pb_simulate.md).

## Value

A data frame with one row per model and columns `model`, `observed` (the
metric of the original fit), `boot_mean`, `boot_sd`, `lower` and `upper`
(summaries of the metric over the bootstrap refits).

## Examples

``` r
fits <- list(
  mpg = glm(vs ~ mpg, data = mtcars, family = binomial()),
  mpg_wt = glm(vs ~ mpg + wt, data = mtcars, family = binomial())
)
pb_compare_models(fits, n = 25, seed = 1)
#> Warning: 1 of 25 bootstrap refits produced warnings (for example convergence problems).
#>    model observed boot_mean  boot_sd    lower    upper
#> 1    mpg 29.53334  26.73515 6.008337 14.06035 34.15406
#> 2 mpg_wt 31.29788  29.76060 5.562452 19.61322 37.31873
```
