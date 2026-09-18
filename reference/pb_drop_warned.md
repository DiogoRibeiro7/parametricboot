# Drop replicates whose refit raised a warning

Marks the bootstrap replicates whose refit produced a warning as
dropped, so that they are excluded from all summaries, plots and
predictions.

## Usage

``` r
pb_drop_warned(results)
```

## Arguments

- results:

  A `pb_boot` object from [`pb_simulate()`](pb_simulate.md) or
  [`pb_parallel()`](pb_parallel.md).

## Value

A `pb_boot` object in which the replicates that raised warnings are
flagged in `failed`, and their estimates, standard errors and refitted
models are removed.

## Details

The typical use is logistic regression on small samples, where some
simulated data sets are perfectly separated. The maximum likelihood
estimate does not exist for such data:
[`glm()`](https://rdrr.io/r/stats/glm.html) warns that fitted
probabilities of 0 or 1 occurred and returns arbitrary, very large
coefficients. A handful of these replicates is enough to ruin bootstrap
means, standard errors and histograms.

Dropping them changes the question being answered: the summaries then
describe the estimator *conditional on the fit being well behaved*.
Report the proportion of dropped replicates alongside the results.
Percentile intervals from [`pb_confint()`](pb_confint.md) are barely
affected by a few extreme replicates and do not need this treatment.

Not every warning signals a useless fit (for mixed models, convergence
warnings are often false alarms), so replicates are never dropped
automatically. Inspect `results$warned` and the affected
`results$replicates` before deciding.

## Examples

``` r
# About 1% of data sets simulated from this model are perfectly separated
fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
res <- suppressWarnings(pb_simulate(fit, n = 300, seed = 2025))
sum(res$warned)
#> [1] 4

pb_key_stats(res)[c("term", "bias", "std_error")]
#>          term       bias std_error
#> 1 (Intercept) -6.5026028 57.581787
#> 2         mpg  0.3300858  2.931462
pb_key_stats(pb_drop_warned(res))[c("term", "bias", "std_error")]
#>          term       bias std_error
#> 1 (Intercept) -1.5726316 4.4847282
#> 2         mpg  0.0800258 0.2217842
```
