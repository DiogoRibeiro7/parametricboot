# Decompose model-conditional predictive variance

Separates between-refit variation of conditional means from expected
conditional outcome variance according to the law of total variance.

## Usage

``` r
pb_predict_variance(results, newdata)
```

## Arguments

- results:

  A pb_boot object from
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  or
  [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md),
  created with `keep_fits = TRUE`.

- newdata:

  Nonempty data frame of covariates for future observations.

## Value

A data frame with `prediction`, `parameter_variance`,
`observation_variance`, `total_variance`, and `successful_replicates`
for each row of `newdata`.

## Details

Supports unweighted Gaussian `lm`, Poisson `glm` and
[`MASS::glm.nb`](https://rdrr.io/pkg/MASS/man/glm.nb.html). Parameter
variance uses the finite-mixture denominator B, not B - 1. No new random
draws are made. These are model-conditional estimates rather than
guarantees of predictive coverage.

## See also

[`pb_predict_interval()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_interval.md),
[`pb_predict_observations()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_observations.md)

## Examples

``` r
fit <- lm(mpg ~ wt + hp, data = mtcars)
boot <- pb_simulate(fit, n = 30, seed = 1, keep_fits = TRUE)
pb_predict_variance(boot, mtcars[1:2, c("wt", "hp")])
#>   prediction parameter_variance observation_variance total_variance
#> 1   23.57233          0.1870949              7.26565       7.452745
#> 2   22.58348          0.1860647              7.26565       7.451714
#>   successful_replicates
#> 1                    30
#> 2                    30
```
