# Bootstrap confidence intervals

Bootstrap confidence intervals

## Usage

``` r
pb_confint(
  results,
  level = 0.95,
  type = c("percentile", "basic", "normal", "student")
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

  Type of interval: `"percentile"`, `"basic"`, `"normal"` or
  `"student"`.

## Value

A data frame with one row per coefficient and columns `term`, `estimate`
(the original estimate), `lower` and `upper`.

## Details

Writing \\\hat\theta\\ for the original estimate and \\\theta^\*\\ for
the bootstrap estimates, the intervals are

- `"percentile"`: the \\\alpha/2\\ and \\1 - \alpha/2\\ quantiles of
  \\\theta^\*\\;

- `"basic"`: \\2\hat\theta\\ minus the upper and lower percentile
  limits;

- `"normal"`: \\\hat\theta - b \pm z\_{1 - \alpha/2} s\\, where \\b\\
  and \\s\\ are the bootstrap estimates of bias and standard error;

- `"student"`: the studentised or bootstrap-t interval, \\(\hat\theta -
  \hat s\\ q\_{1 - \alpha/2},\\ \hat\theta - \hat s\\ q\_{\alpha/2})\\,
  where \\\hat s\\ is the standard error of the original fit and \\q\\
  are quantiles of the studentised bootstrap estimates \\(\theta^\* -
  \hat\theta) / s^\*\\, each replicate being scaled by its own standard
  error \\s^\*\\.

The studentised interval replaces the normal quantiles of the Wald
interval by bootstrap ones. It is the most accurate of the four when the
standard error is estimated reliably (its coverage error is of smaller
order in the sample size), and it is exact for the normal linear model,
where it reproduces the usual t interval. Scaling each replicate by its
own standard error also makes it insensitive to degenerate refits, such
as perfectly separated logistic regressions, whose huge estimates come
with huge standard errors. It is not invariant to reparametrisation, and
it needs more replicates than the percentile interval because it relies
on the tails of a ratio. It is not available for parameters without a
standard error, such as the variance components of mixed models: their
limits are `NA`, with a warning.

## References

Davison, A. C. and Hinkley, D. V. (1997) *Bootstrap Methods and their
Application*, chapter 5. Cambridge University Press.

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
res <- pb_simulate(fit, n = 50, seed = 1)
#> Warning: 1 of 50 bootstrap refits produced warnings (for example convergence problems).

pb_confint(res)
#>          term   estimate       lower     upper
#> 1 (Intercept) -8.8330726 -27.1853321 -5.754519
#> 2         mpg  0.4304135   0.2688677  1.372662
pb_confint(res, level = 0.9, type = "basic")
#>          term   estimate       lower     upper
#> 1 (Intercept) -8.8330726 -11.7866311 5.7633983
#> 2         mpg  0.4304135  -0.3120883 0.5856325
pb_confint(res, type = "student")
#>          term   estimate       lower      upper
#> 1 (Intercept) -8.8330726 -13.3798395 -4.1682381
#> 2         mpg  0.4304135   0.1930526  0.6800896
```
