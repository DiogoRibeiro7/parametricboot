# Predict using retained bootstrap refits or cached predictions

`pb_predict()` is the concise, preferred spelling of
[`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md).
Both use the same implementation and results.

## Usage

``` r
pb_predict(results, newdata = NULL, ...)
```

## Arguments

- results:

  A `pb_boot` object from
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  or
  [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md).

- newdata:

  Optional data frame to predict for. If `NULL`, predictions use the
  original fitting observations, unless cached predictions are
  available.

- ...:

  Additional arguments passed to
  [`predict()`](https://rdrr.io/r/stats/predict.html), such as
  `type = "response"`.

## Value

A numeric matrix with one row per observation and one column per
successful bootstrap prediction.

## Details

The longer function name remains available for backward compatibility.

## See also

[`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md),
[`pb_predict_interval()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_interval.md)

## Examples

``` r
fit <- stats::lm(mpg ~ wt + hp, data = mtcars)
res <- pb_simulate(fit, n = 20, seed = 1)
pb_predict(res, mtcars[1:2, c("wt", "hp")])
#>                   [,1]     [,2]     [,3]     [,4]     [,5]     [,6]     [,7]
#> Mazda RX4     23.89247 23.66304 23.92203 23.31932 22.72327 24.56666 23.40018
#> Mazda RX4 Wag 23.01236 22.58162 22.71898 22.46151 21.52304 23.69369 22.60281
#>                   [,8]     [,9]    [,10]    [,11]    [,12]    [,13]    [,14]
#> Mazda RX4     23.38615 23.82894 24.09327 23.74203 23.43989 23.55418 23.69484
#> Mazda RX4 Wag 22.31167 22.89260 23.27253 22.59271 22.39074 22.66001 22.51025
#>                  [,15]    [,16]    [,17]    [,18]    [,19]    [,20]
#> Mazda RX4     23.33961 22.86921 23.65379 23.70543 23.47307 23.04491
#> Mazda RX4 Wag 22.36712 22.24442 22.78445 22.45503 22.70654 22.19602
```
