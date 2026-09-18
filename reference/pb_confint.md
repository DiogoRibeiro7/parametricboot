# Bootstrap confidence intervals

Bootstrap confidence intervals

## Usage

``` r
pb_confint(results, level = 0.95, type = c("percentile", "basic", "normal"))
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
  and \\s\\ are the bootstrap estimates of bias and standard error.

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
```
