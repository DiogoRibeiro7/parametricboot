# Methods for `pb_boot` objects

[`print()`](https://rdrr.io/r/base/print.html) gives a short overview of
a parametric bootstrap,
[`summary()`](https://rdrr.io/r/base/summary.html) returns the table of
[`pb_summary_table()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_summary_table.md),
and [`confint()`](https://rdrr.io/r/stats/confint.html) returns the
intervals of
[`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md)
in the matrix layout used by
[`stats::confint()`](https://rdrr.io/r/stats/confint.html).

## Usage

``` r
# S3 method for class 'pb_boot'
print(x, ...)

# S3 method for class 'pb_boot'
summary(object, ...)

# S3 method for class 'pb_boot'
confint(
  object,
  parm,
  level = 0.95,
  type = c("percentile", "basic", "normal", "student"),
  ...
)
```

## Arguments

- x, object:

  A `pb_boot` object from
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  or
  [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md).

- ...:

  For [`summary()`](https://rdrr.io/r/base/summary.html), arguments
  passed to
  [`pb_summary_table()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_summary_table.md);
  otherwise unused.

- parm:

  Names of the coefficients to return intervals for. Defaults to all
  coefficients.

- level:

  Confidence level, strictly between 0 and 1.

- type:

  Type of interval; see
  [`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md).

## Value

[`print()`](https://rdrr.io/r/base/print.html) returns `x` invisibly.
[`summary()`](https://rdrr.io/r/base/summary.html) returns a data frame.
[`confint()`](https://rdrr.io/r/stats/confint.html) returns a matrix
with one row per coefficient and columns giving the lower and upper
limits.

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
res <- pb_simulate(fit, n = 50, seed = 1)
#> Warning: 1 of 50 bootstrap refits produced warnings (for example convergence problems).

print(res)
#> <pb_boot> Parametric bootstrap
#>   Model:      glm (binomial)
#>   Replicates: 50 (1 with warnings)
#>   Terms:      (Intercept), mpg
summary(res)
#>          term   estimate   boot_mean       bias std_error        mse coverage
#> 1 (Intercept) -8.8330726 -11.3837215 -2.5506490  7.703586 64.6641446        1
#> 2         mpg  0.4304135   0.5582403  0.1278268  0.381317  0.1588343        1
#>         lower     upper
#> 1 -27.1853321 -5.754519
#> 2   0.2688677  1.372662
confint(res, level = 0.9)
#>                     5 %      95 %
#> (Intercept) -23.4295435 -5.879514
#> mpg           0.2751945  1.172915
```
