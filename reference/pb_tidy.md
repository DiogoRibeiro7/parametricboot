# Convert bootstrap estimates to long format

Convert bootstrap estimates to long format

## Usage

``` r
pb_tidy(results)
```

## Arguments

- results:

  A `pb_boot` object from
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  or
  [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md).

## Value

A data frame with one row per successful replicate and coefficient, and
columns `replicate`, `term` and `estimate`. It is ready for use with
'ggplot2' or 'dplyr'.

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
res <- pb_simulate(fit, n = 50, seed = 1)
#> Warning: 1 of 50 bootstrap refits produced warnings (for example convergence problems).
head(pb_tidy(res))
#>   replicate        term   estimate
#> 1         1 (Intercept) -9.5640711
#> 2         1         mpg  0.4545191
#> 3         2 (Intercept) -7.6705492
#> 4         2         mpg  0.3827237
#> 5         3 (Intercept) -8.4098681
#> 6         3         mpg  0.4089459
```
