# Simulate future observations from parametric bootstrap refits

Draws observation-level outcomes from the sampling model of each
successful bootstrap refit, incorporating both fitted-model and process
uncertainty.

## Usage

``` r
pb_predict_observations(results, newdata, seed = NULL)
```

## Arguments

- results:

  A `pb_boot` object from
  [`pb_simulate`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  or
  [`pb_parallel`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md),
  fitted with `keep_fits = TRUE`.

- newdata:

  Nonempty data frame of covariates for future observations.

- seed:

  Optional seed for future response sampling, separate from the original
  bootstrap seed.

## Details

Initially supported: unweighted Gaussian linear models, unweighted
Poisson GLMs, and unweighted negative-binomial models fitted using
[`MASS::glm.nb()`](https://rdrr.io/pkg/MASS/man/glm.nb.html). Gaussian
observations are sampled using
[`rnorm()`](https://rdrr.io/r/stats/Normal.html) with each refit's
residual standard deviation; Poisson observations use
[`rpois()`](https://rdrr.io/r/stats/Poisson.html) and negative-binomial
observations use [`rnbinom()`](https://rdrr.io/r/stats/NegBinomial.html)
with each refit's re-estimated `theta`. Binomial, mixed-effects, and Cox
models, as well as non-unit case weights, are not supported by this
function. The approach is model-conditional predictive simulation rather
than an exact small-sample frequentist prediction interval.

## Value

A numeric matrix with one row per future observation and one column per
successful bootstrap refit. Each entry is a newly sampled observation
conditional on the corresponding refitted model.

## See also

[`pb_predict_interval`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_interval.md),
[`pb_predict_boot`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md)

## Examples

``` r
fit <- lm(mpg ~ wt + hp, data = mtcars)
boot <- pb_simulate(fit, n = 30, seed = 1, keep_fits = TRUE)
new_cars <- mtcars[1:2, c("wt", "hp")]
draws <- pb_predict_observations(boot, new_cars, seed = 2)
dim(draws)
#> [1]  2 30
```
