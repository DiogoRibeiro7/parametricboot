# Plot the bootstrap distribution of the estimates

Draws a histogram of the bootstrap estimates of each coefficient, with
the original estimate marked by a vertical line.

## Usage

``` r
pb_plot_estimates(results, parameter = NULL, bins = 30)
```

## Arguments

- results:

  A `pb_boot` object from [`pb_simulate()`](pb_simulate.md) or
  [`pb_parallel()`](pb_parallel.md).

- parameter:

  Character vector of coefficient names to plot. The default, `NULL`,
  plots all of them.

- bins:

  Number of histogram bins.

## Value

A `ggplot` object.

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
res <- pb_simulate(fit, n = 100, seed = 1)
#> Warning: 2 of 100 bootstrap refits produced warnings (for example convergence problems).

pb_plot_estimates(res)

pb_plot_estimates(res, parameter = "mpg")
```
