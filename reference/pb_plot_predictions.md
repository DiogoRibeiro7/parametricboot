# Plot predictions with bootstrap intervals

Plots the predictions of the original model for `newdata` together with
percentile intervals computed from the bootstrap refits.

## Usage

``` r
pb_plot_predictions(results, newdata, x = NULL, level = 0.95, ...)
```

## Arguments

- results:

  A `pb_boot` object from [`pb_simulate()`](pb_simulate.md) or
  [`pb_parallel()`](pb_parallel.md).

- newdata:

  Data frame to predict for.

- x:

  Name of the column of `newdata` to put on the horizontal axis. A
  numeric column gives a line with a ribbon; any other column, or the
  default `NULL` (row number), gives points with error bars.

- level:

  Level of the bootstrap percentile interval.

- ...:

  Additional arguments passed to
  [`stats::predict()`](https://rdrr.io/r/stats/predict.html), such as
  `type = "response"`, or `re.form = NA` for population-level
  predictions from mixed models.

## Value

A `ggplot` object.

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
res <- pb_simulate(fit, n = 100, seed = 1)
#> Warning: 2 of 100 bootstrap refits produced warnings (for example convergence problems).

new_cars <- data.frame(mpg = seq(10, 35, by = 1))
pb_plot_predictions(res, new_cars, x = "mpg", type = "response")
```
