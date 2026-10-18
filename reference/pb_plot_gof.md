# Plot a simulated goodness-of-fit reference distribution

Plots valid bootstrap goodness-of-fit statistics against the observed
statistic.

## Usage

``` r
pb_plot_gof(test, bins = 30L)
```

## Arguments

- test:

  A `pb_gof` object returned by
  [`pb_gof`](https://diogoribeiro7.github.io/parametricboot/reference/pb_gof.md).

- bins:

  Positive number of histogram bins.

## Details

The histogram shows the empirical reference distribution without
imposing a chi-squared approximation. The dashed vertical line indicates
the observed discrepancy. The plot preserves discreteness and ties in
the bootstrap values.

## Value

A `ggplot` object.

## See also

[`pb_gof`](https://diogoribeiro7.github.io/parametricboot/reference/pb_gof.md),
[`pb_gof_mc_error`](https://diogoribeiro7.github.io/parametricboot/reference/pb_gof_mc_error.md)

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
check <- pb_gof(fit, n = 30, seed = 1)
#> Warning: 1 of 30 bootstrap refits produced warnings (for example convergence problems).
pb_plot_gof(check)
```
