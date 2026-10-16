# Monte Carlo errors of bootstrap bias and standard error

Reports the uncertainty from using a finite number of bootstrap refits
to estimate bootstrap bias and standard deviation.

## Usage

``` r
pb_mc_error(results)
```

## Arguments

- results:

  A `pb_boot` object from
  [`pb_simulate`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  or
  [`pb_parallel`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md).

## Details

For each coefficient with B finite estimates, the Monte Carlo standard
error of bias (conditional on the fitted model) is the bootstrap
standard deviation divided by the square root of B. The Monte Carlo
error of that standard deviation is estimated by a first-order delta
method using the empirical fourth central moment. The latter is not
estimated for fewer than four finite values or zero empirical
dispersion. These quantities describe Monte Carlo precision, not
uncertainty about the fitted model or estimator. Failed refits and
non-finite coefficient estimates are excluded separately by parameter,
and missingness may be selective.

## Value

A data frame with `term`, `replicates`, `failed_replicates`, `bias`,
`bias_mc_se`, `std_error`, and `std_error_mc_se`. Here `std_error` means
bootstrap standard deviation; `std_error_mc_se` is its Monte Carlo
standard error.

## See also

[`pb_key_stats`](https://diogoribeiro7.github.io/parametricboot/reference/pb_key_stats.md),
[`pb_confint_mc_error`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint_mc_error.md),
[`pb_lrt_mc_error`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt_mc_error.md)

## Examples

``` r
model <- lm(mpg ~ wt, data = mtcars)
result <- pb_simulate(model, n = 30, seed = 7, keep_fits = FALSE)
pb_mc_error(result)
#>          term replicates failed_replicates       bias bias_mc_se std_error
#> 1 (Intercept)         30                 0 -0.3722250 0.25145166 1.3772575
#> 2          wt         30                 0  0.1208684 0.07815605 0.4280783
#>   std_error_mc_se
#> 1      0.26120347
#> 2      0.08660615
```
