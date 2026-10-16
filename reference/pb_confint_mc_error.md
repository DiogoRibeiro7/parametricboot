# Monte Carlo precision of bootstrap confidence interval limits

Reports finite-replicate uncertainty of the endpoints of quantile-based
bootstrap confidence intervals.

## Usage

``` r
pb_confint_mc_error(
  results,
  level = 0.95,
  type = c("percentile", "basic", "student"),
  mc_level = 0.95
)
```

## Arguments

- results:

  A `pb_boot` object from
  [`pb_simulate`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  or
  [`pb_parallel`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md).

- level:

  Coverage level for the underlying bootstrap confidence interval.

- type:

  One of `"percentile"`, `"basic"`, or `"student"`. Rank bounds are not
  provided for normal-approximation intervals.

- mc_level:

  Per-endpoint Monte Carlo confidence level, separate from `level`.

## Details

Distribution-free order-statistic bounds for each bootstrap tail
quantile are derived using binomial ranks, then mapped into percentile,
basic or studentised confidence interval units. The Monte Carlo bounds
apply separately to the lower and upper endpoint; they are not a joint
region. Unbounded bounds signal too few bootstrap replicates to provide
a finite rank guarantee for a tail quantile. The method conditions on
independently simulated, successful finite refits and does not measure
statistical sampling or model uncertainty. Parameters without usable
studentised confidence intervals have missing Monte Carlo bounds.

## Value

A data frame with `term`, the original unmodified `lower` and `upper`
confidence interval endpoints, `lower_mc_low`, `lower_mc_high`,
`upper_mc_low`, `upper_mc_high`, and `replicates`.

## See also

[`pb_confint`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md),
[`pb_mc_error`](https://diogoribeiro7.github.io/parametricboot/reference/pb_mc_error.md),
[`pb_lrt_mc_error`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt_mc_error.md)

## Examples

``` r
model <- lm(mpg ~ wt, data = mtcars)
result <- pb_simulate(model, n = 30, seed = 7, keep_fits = FALSE)
pb_confint_mc_error(result, level = 0.8, mc_level = 0.9)
#>          term     lower     upper lower_mc_low lower_mc_high upper_mc_low
#> 1 (Intercept) 35.517189 38.002131    33.559757     35.925463    37.725176
#> 2          wt -5.587498 -4.817599    -6.635923     -5.487411    -4.954131
#>   upper_mc_high replicates
#> 1     41.239202         30
#> 2     -4.158725         30
```
