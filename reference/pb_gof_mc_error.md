# Monte Carlo uncertainty of a bootstrap goodness-of-fit p-value

Quantifies simulation uncertainty in a parametric-bootstrap
goodness-of-fit tail probability.

## Usage

``` r
pb_gof_mc_error(test, level = 0.95)
```

## Arguments

- test:

  A `pb_gof` object returned by
  [`pb_gof`](https://diogoribeiro7.github.io/parametricboot/reference/pb_gof.md).

- level:

  Confidence level for the exact binomial limits.

## Details

The original add-one corrected p-value is \\(1+k)/(1+B)\\, with \\k\\
selected-tail exceedances among \\B\\ successful refits. The plug-in
Monte Carlo standard error and exact Clopper-Pearson interval apply to
the raw tail probability \\k/B\\, not the add-one adjusted p-value. When
no simulated value is as extreme as the observation, the plug-in
standard error is zero, while the exact confidence interval has a
positive upper endpoint. These calculations condition on the fitted
model and successful, independent refits and do not account for
selective refit failure or model misspecification.

## Value

A one-row data frame with `tail`, `p_value`, `tail_probability`,
`mc_standard_error`, `lower`, `upper`, `exceedances`,
`valid_replicates`, and `failed_replicates`.

## See also

[`pb_plot_gof`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_gof.md),
[`pb_lrt_mc_error`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt_mc_error.md)

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
check <- pb_gof(fit, n = 30, seed = 1)
#> Warning: 1 of 30 bootstrap refits produced warnings (for example convergence problems).
pb_gof_mc_error(check)
#>      tail  p_value tail_probability mc_standard_error     lower     upper
#> 1 greater 0.483871        0.4666667        0.09108401 0.2834181 0.6567448
#>   exceedances valid_replicates failed_replicates
#> 1          14               30                 0
```
