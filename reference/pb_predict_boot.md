# Predict with bootstrap uncertainty

Computes predictions from every refitted bootstrap model.

## Usage

``` r
pb_predict_boot(results, newdata = NULL, ...)
```

## Arguments

- results:

  A `pb_boot` object from
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  or
  [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md).

- newdata:

  Optional data frame to predict for. If `NULL`, predictions are made
  for the observations used to fit the model.

- ...:

  Additional arguments passed to
  [`stats::predict()`](https://rdrr.io/r/stats/predict.html), such as
  `type = "response"`, or `re.form = NA` for population-level
  predictions from mixed models.

## Value

A numeric matrix with one row per observation and one column per
successful bootstrap replicate.

## Examples

``` r
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
res <- pb_simulate(fit, n = 50, seed = 1)
#> Warning: 1 of 50 bootstrap refits produced warnings (for example convergence problems).

new_cars <- data.frame(mpg = c(15, 20, 25))
preds <- pb_predict_boot(res, new_cars, type = "response")
dim(preds)
#> [1]  3 50

# 95% percentile intervals for the predicted probabilities
t(apply(preds, 1, quantile, probs = c(0.025, 0.975)))
#>         2.5%     97.5%
#> 1 0.00138951 0.1834619
#> 2 0.24489623 0.6545546
#> 3 0.65074995 0.9989977
```
