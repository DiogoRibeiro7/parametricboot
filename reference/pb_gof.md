# Parametric-bootstrap goodness-of-fit test

Simulates and refits responses under a fitted count or binomial
regression model to approximate the goodness-of-fit statistic's
reference distribution.

## Usage

``` r
pb_gof(
  model,
  n = 1000,
  statistic = c("deviance", "pearson", "zeros"),
  seed = NULL,
  workers = 1L
)
```

## Arguments

- model:

  Supported binomial, Poisson or MASS negative-binomial GLM.

- n:

  Positive number of bootstrap replicates.

- statistic:

  Deviance, Pearson residual sum of squares, or zero count.

- seed:

  Optional reproducibility seed.

- workers:

  Number of processes for refitting.

## Details

The upper-tail p-value uses (1 + exceedances) / (1 + valid replicates).
Failed refits are excluded. This procedure is conditional on the fitted
sampling model and does not prove model correctness. The zero-count
statistic is supported only for unweighted count data.

## Value

A `pb_gof` object with fields `statistic`, `observed`, `reference`,
`p_value`, `n`, `failed`, `warned`, `model`, `seed`, and `call`.

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
pb_gof(fit, n = 30, seed = 1)
#> Warning: 1 of 30 bootstrap refits produced warnings (for example convergence problems).
#> $statistic
#> [1] "deviance"
#> 
#> $observed
#> [1] 25.53334
#> 
#> $reference
#>  [1] 23.956363 27.875025 26.288432 24.234940 12.957417 23.978476 31.622177
#>  [8] 12.838731  6.228143 23.776692 22.799441 21.073724 24.979534 22.723471
#> [15] 17.606170 24.418136 27.270766 26.224846 27.352651 24.403916 27.704294
#> [22] 29.175307 12.615150 20.560511 25.714326 31.187912 28.627510 29.613630
#> [29] 32.147481 26.041001
#> 
#> $p_value
#> [1] 0.483871
#> 
#> $n
#> [1] 30
#> 
#> $failed
#>  [1] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [13] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [25] FALSE FALSE FALSE FALSE FALSE FALSE
#> 
#> $warned
#>  [1] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE  TRUE FALSE FALSE FALSE
#> [13] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
#> [25] FALSE FALSE FALSE FALSE FALSE FALSE
#> 
#> $model
#> 
#> Call:  glm(formula = vs ~ mpg, family = binomial(), data = mtcars)
#> 
#> Coefficients:
#> (Intercept)          mpg  
#>     -8.8331       0.4304  
#> 
#> Degrees of Freedom: 31 Total (i.e. Null);  30 Residual
#> Null Deviance:       43.86 
#> Residual Deviance: 25.53     AIC: 29.53
#> 
#> $seed
#> [1] 1
#> 
#> $call
#> pb_gof(model = fit, n = 30, seed = 1)
#> 
#> attr(,"class")
#> [1] "pb_gof"
```
