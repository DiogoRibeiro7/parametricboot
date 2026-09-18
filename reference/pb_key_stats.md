# Bootstrap bias, standard error, MSE and coverage

In a parametric bootstrap the fitted model plays the role of the truth,
so the behaviour of the estimator around the original estimate
\\\hat\theta\\ estimates its behaviour around the true parameter.

## Usage

``` r
pb_key_stats(results, level = 0.95)
```

## Arguments

- results:

  A `pb_boot` object from [`pb_simulate()`](pb_simulate.md) or
  [`pb_parallel()`](pb_parallel.md).

- level:

  Nominal level of the Wald intervals whose coverage is estimated.

## Value

A data frame with one row per coefficient and columns

- `term`:

  coefficient name.

- `estimate`:

  original estimate \\\hat\theta\\.

- `boot_mean`:

  mean of the bootstrap estimates.

- `bias`:

  `boot_mean - estimate`.

- `std_error`:

  standard deviation of the bootstrap estimates.

- `mse`:

  mean squared error of the bootstrap estimates around `estimate`.

- `coverage`:

  proportion of replicates whose Wald interval (estimate plus or minus a
  normal quantile times the standard error) contains `estimate`. Values
  far from `level` indicate that the usual Wald intervals are unreliable
  for this model.

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
res <- pb_simulate(fit, n = 50, seed = 1)
#> Warning: 1 of 50 bootstrap refits produced warnings (for example convergence problems).
pb_key_stats(res)
#>          term   estimate   boot_mean       bias std_error        mse coverage
#> 1 (Intercept) -8.8330726 -11.3837215 -2.5506490  7.703586 64.6641446        1
#> 2         mpg  0.4304135   0.5582403  0.1278268  0.381317  0.1588343        1
```
