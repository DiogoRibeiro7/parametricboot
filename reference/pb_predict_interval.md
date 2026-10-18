# Prediction intervals for new observations

Constructs a model-conditional prediction interval for a future
response, rather than a confidence interval for the fitted conditional
mean.

## Usage

``` r
pb_predict_interval(results, newdata, level = 0.95, seed = NULL)
```

## Arguments

- results:

  A `pb_boot` object from
  [`pb_simulate`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  or
  [`pb_parallel`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md),
  with retained refits.

- newdata:

  Nonempty data frame giving future covariates.

- level:

  Predictive quantile interval level, strictly between zero and one.

- seed:

  Optional RNG seed for future outcomes, independent from the bootstrap
  fit seed.

## Details

For each bootstrap refit, an additional observation is independently
drawn from the fitted sampling model. Empirical quantiles of these draws
combine parameter uncertainty and response noise. The original model's
conditional mean is reported separately as `prediction`. The intervals
are approximate, conditional on the model assumptions, and require
retained refits. The method initially supports unweighted Gaussian
linear, Poisson GLM and MASS negative-binomial models only.

## Value

Data frame with columns `prediction`, `lower`, `upper`, and
`successful_replicates`, one row for each future observation.

## See also

[`pb_predict_observations`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_observations.md),
[`pb_predict_boot`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md)

## Examples

``` r
fit <- lm(mpg ~ wt + hp, data = mtcars)
boot <- pb_simulate(fit, n = 30, seed = 1)
pb_predict_interval(boot, mtcars[1:2, c("wt", "hp")],
                    level = 0.9, seed = 2)
#>   prediction    lower    upper successful_replicates
#> 1   23.57233 20.64055 28.04633                    30
#> 2   22.58348 16.20530 27.96269                    30
```
