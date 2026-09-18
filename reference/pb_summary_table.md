# Summarise bootstrap statistics and confidence intervals

Combines
[`pb_key_stats()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_key_stats.md)
and
[`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md)
into a single table.

## Usage

``` r
pb_summary_table(
  results,
  level = 0.95,
  type = c("percentile", "basic", "normal")
)
```

## Arguments

- results:

  A `pb_boot` object from
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  or
  [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md).

- level:

  Confidence level, strictly between 0 and 1.

- type:

  Type of interval: `"percentile"`, `"basic"` or `"normal"`.

## Value

A data frame with one row per coefficient: the columns of
[`pb_key_stats()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_key_stats.md)
followed by the `lower` and `upper` confidence limits of
[`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md).

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
res <- pb_simulate(fit, n = 50, seed = 1)
#> Warning: 1 of 50 bootstrap refits produced warnings (for example convergence problems).
pb_summary_table(res)
#>          term   estimate   boot_mean       bias std_error        mse coverage
#> 1 (Intercept) -8.8330726 -11.3837215 -2.5506490  7.703586 64.6641446        1
#> 2         mpg  0.4304135   0.5582403  0.1278268  0.381317  0.1588343        1
#>         lower     upper
#> 1 -27.1853321 -5.754519
#> 2   0.2688677  1.372662
```
