# Plot bootstrap diagnostics

Draws, for each coefficient, the running mean of the bootstrap estimates
against the number of replicates. The running mean settles down once
enough replicates have been drawn, so a curve that is still drifting at
the right edge suggests increasing `n`. The grey points are the
individual estimates and the dashed line is the original estimate; a
persistent gap between the curve and the dashed line is the bootstrap
estimate of bias.

## Usage

``` r
pb_plot_diagnostics(results, parameter = NULL)
```

## Arguments

- results:

  A `pb_boot` object from [`pb_simulate()`](pb_simulate.md) or
  [`pb_parallel()`](pb_parallel.md).

- parameter:

  Character vector of coefficient names to plot. The default, `NULL`,
  plots all of them.

## Value

A `ggplot` object.

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
res <- pb_simulate(fit, n = 100, seed = 1)
#> Warning: 2 of 100 bootstrap refits produced warnings (for example convergence problems).
pb_plot_diagnostics(res)
```
