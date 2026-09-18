# Resample the rows of a data frame with replacement

A small helper for the *nonparametric* (case-resampling) bootstrap,
useful as a point of comparison for the parametric bootstrap of
[`pb_simulate()`](pb_simulate.md).

## Usage

``` r
pb_resample(data, size = nrow(data))
```

## Arguments

- data:

  Data frame to resample.

- size:

  Number of rows to draw. Defaults to `nrow(data)`.

## Value

A data frame with `size` rows drawn with replacement from `data`.

## Examples

``` r
set.seed(1)
boot_cars <- pb_resample(mtcars)
coef(lm(mpg ~ wt, data = boot_cars))
#> (Intercept)          wt 
#>   37.144812   -5.512313 
```
