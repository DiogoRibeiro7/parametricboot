# Parametric bootstrap likelihood-ratio test for nested models

Tests a null model against a larger alternative with the
likelihood-ratio statistic, using the parametric bootstrap instead of
the chi-squared approximation to obtain its null distribution.

## Usage

``` r
pb_lrt(null, alternative, n = 1000, ..., seed = NULL, workers = 1)

# S3 method for class 'pb_lrt'
print(x, digits = 3, ...)
```

## Arguments

- null, alternative:

  Fitted models supported by
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md),
  with `null` nested in `alternative`.

- n:

  Number of bootstrap replicates. Use at least 1000 for p-values near
  conventional significance levels.

- ...:

  For `pb_lrt()`, additional arguments used when refitting both models;
  see
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md).
  Unused by [`print()`](https://rdrr.io/r/base/print.html).

- seed:

  Optional single number making the test reproducible; see
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md).

- workers:

  Number of parallel worker processes; see
  [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md).

- x:

  A `pb_lrt` object.

- digits:

  Number of significant digits to print.

## Value

An object of class `pb_lrt`: a list with elements

- `statistic`, `df`:

  the observed likelihood-ratio statistic and its degrees of freedom.

- `table`:

  data frame with one row per test (`"chisq"`, `"bartlett"`,
  `"bootstrap"`) and columns `test`, `statistic`, `df` and `p_value`.

- `reference`:

  the `n` bootstrap statistics, `NA` for dropped replicates.

- `null`, `alternative`:

  the two models, refitted by maximum likelihood if necessary.

- `n`, `failed`, `warned`, `seed`, `call`:

  bookkeeping, as for
  [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md).

Use
[`pb_plot_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_lrt.md)
to compare the bootstrap null distribution with the chi-squared
approximation.

## Details

The statistic is \\T = 2(\ell_1 - \ell_0)\\, twice the difference
between the maximised log-likelihoods of `alternative` and `null`. Its
null distribution is estimated by simulating `n` responses from the
fitted `null` model, refitting *both* models to each of them and
recomputing \\T\\. Three p-values are reported:

- `"chisq"`: the usual asymptotic p-value, from a chi-squared
  distribution with `df` degrees of freedom;

- `"bartlett"`: the same, after rescaling \\T\\ by `df` divided by the
  bootstrap mean of the statistic (an empirical Bartlett correction). It
  repairs the scale of the chi-squared approximation but not its shape,
  so it is no more reliable than `"chisq"` in boundary problems;

- `"bootstrap"`: \\(1 + \\\\T^\*\_b \ge T\\) / (1 + B)\\, where \\B\\ is
  the number of valid replicates. It makes no distributional assumption
  and can never be smaller than \\1 / (1 + B)\\.

The chi-squared approximation is poor in small samples, where it usually
gives p-values that are too small, and it fails altogether when the null
hypothesis puts a parameter on the boundary of its space. The standard
example is testing whether a variance component is zero: the statistic
is then exactly zero in a large share of samples and the asymptotic
p-value is roughly twice what it should be.

The models may be of different classes as long as their log-likelihoods
are comparable, so a random intercept can be tested with an
[`lm()`](https://rdrr.io/r/stats/lm.html) or
[`glm()`](https://rdrr.io/r/stats/glm.html) fit as the null and an
`lmer()` or `glmer()` fit as the alternative. Mixed models fitted by
REML are refitted by maximum likelihood first, with a message. For
`coxph` models the partial likelihood is used, the null may be the model
without covariates, `Surv(time, status) ~ 1`, and both models must be
stratified in the same way.

Whether the models are nested cannot be checked in general; it is only
verified that they were fitted to the same response, that `alternative`
has more parameters and that the observed statistic is not negative. A
replicate in which a refit fails, or in which the statistic is negative
(the alternative converged to a worse optimum than the null), is
dropped.

## References

Davison, A. C. and Hinkley, D. V. (1997) *Bootstrap Methods and their
Application*, chapter 4. Cambridge University Press.

Halekoh, U. and Hojsgaard, S. (2014) A Kenward-Roger approximation and
parametric bootstrap methods for tests in linear mixed models: the R
package pbkrtest. *Journal of Statistical Software*, **59**(9), 1-32.
[doi:10.18637/jss.v059.i09](https://doi.org/10.18637/jss.v059.i09)

## See also

[`pb_compare_models()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_compare_models.md)
for comparing models that are not nested.

## Examples

``` r
# Does the effect of dose differ between the sexes? (Collett, 1991)
budworm <- data.frame(
  sex = rep(c("M", "F"), each = 6),
  dose = rep(c(1, 2, 4, 8, 16, 32), times = 2),
  dead = c(1, 4, 9, 13, 18, 20, 0, 2, 6, 10, 12, 16),
  n = 20
)
common <- glm(cbind(dead, n - dead) ~ sex + log2(dose), data = budworm, family = binomial())
separate <- update(common, . ~ sex * log2(dose))

test <- pb_lrt(common, separate, n = 200, seed = 1)
test
#> <pb_lrt> Parametric bootstrap likelihood-ratio test
#>   Null:        cbind(dead, n - dead) ~ sex + log2(dose)
#>   Alternative: cbind(dead, n - dead) ~ sex + log2(dose) + sex:log2(dose)
#>   Replicates:  200
#>   Statistic:   1.76 on 1 df
#> 
#>                          p.value
#> Chi-squared (asymptotic)   0.184
#> Bartlett-corrected         0.168
#> Parametric bootstrap       0.159
test$table
#>        test statistic df   p_value
#> 1     chisq  1.763337  1 0.1842088
#> 2  bartlett  1.900330  1 0.1680414
#> 3 bootstrap  1.763337 NA 0.1592040
```
