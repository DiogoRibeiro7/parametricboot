# Monte Carlo uncertainty for a parametric bootstrap likelihood-ratio p-value

Reports Monte Carlo uncertainty for the likelihood-ratio bootstrap
exceedance probability, conditional on successful refits.

## Usage

``` r
pb_lrt_mc_error(test, level = 0.95)
```

## Arguments

- test:

  A `pb_lrt` object returned by
  [`pb_lrt`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md).

- level:

  Confidence level for the exact binomial interval.

## Details

The original bootstrap p-value \\(1+k)/(1+B)\\ is preserved, where \\k\\
of the \\B\\ valid bootstrap statistics exceed or equal the observed
test statistic. The Monte Carlo standard error is the binomial plug-in
estimate based on \\k/B\\; the interval is the exact Clopper-Pearson
interval for that exceedance probability. When \\k=0\\, the plug-in
standard error is zero but the interval has a positive upper limit.
Failed refits are excluded. The interval does not cover model or
parameter uncertainty and is conditional on the validity and
independence of successful bootstrap replicates.

## Value

A one-row data frame with `p_value`, `exceedance_probability`,
`mc_standard_error`, `lower`, `upper`, `exceedances`,
`valid_replicates`, and `failed_replicates`.

## Examples

``` r
null <- lm(mpg ~ wt, data = mtcars)
alt <- lm(mpg ~ wt + hp, data = mtcars)
test <- pb_lrt(null, alt, n = 30, seed = 1)
pb_lrt_mc_error(test)
#>      p_value exceedance_probability mc_standard_error lower     upper
#> 1 0.03225806                      0                 0     0 0.1157033
#>   exceedances valid_replicates failed_replicates
#> 1           0               30                 0
```
