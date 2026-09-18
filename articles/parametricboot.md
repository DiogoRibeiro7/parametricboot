# Getting started with parametricboot

## The idea

Standard errors and confidence intervals for regression models usually
rest on large-sample approximations. The **parametric bootstrap**
checks, and if necessary replaces, those approximations by simulation:

1.  fit the model to the data;
2.  simulate a new response from the *fitted* model, keeping the
    covariates fixed;
3.  refit the model to the simulated response;
4.  repeat steps 2 and 3 many times.

Because the data-generating mechanism in step 2 is known exactly (it is
the fitted model), the spread of the refitted estimates around the
original one shows how the estimator behaves in samples like yours:
whether it is biased, how variable it is, and whether the textbook
intervals achieve their nominal coverage.

parametricboot runs this loop for
[`lm()`](https://rdrr.io/r/stats/lm.html),
[`glm()`](https://rdrr.io/r/stats/glm.html),
[`lme4::lmer()`](https://rdrr.io/pkg/lme4/man/lmer.html),
[`lme4::glmer()`](https://rdrr.io/pkg/lme4/man/glmer.html) and
[`survival::coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) fits,
and provides tools to summarise the result.

``` r

library(parametricboot)
```

## A dose-response experiment

Collett (1991) describes an experiment in which batches of 20 tobacco
budworm moths of each sex were exposed to six doses of a pyrethroid. The
response is the number of moths killed.

``` r

budworm <- data.frame(
  sex = rep(c("M", "F"), each = 6),
  dose = rep(c(1, 2, 4, 8, 16, 32), times = 2),
  dead = c(1, 4, 9, 13, 18, 20, 0, 2, 6, 10, 12, 16),
  n = 20
)
fit <- glm(cbind(dead, n - dead) ~ sex + log2(dose), data = budworm, family = binomial())
```

[`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
draws the replicates. With `seed`, the result is reproducible and your
session’s random number stream is left untouched.

``` r

res <- pb_simulate(fit, n = 500, seed = 2025)
res
#> <pb_boot> Parametric bootstrap
#>   Model:      glm (binomial)
#>   Replicates: 500
#>   Terms:      (Intercept), sexM, log2(dose)
```

The model is refitted by re-evaluating its call on the original data, so
the two-column response and the `log2(dose)` term need no special
treatment. The only requirement is that the model was fitted with a
`data` argument.

### Summaries

``` r

pb_summary_table(res)
#>          term  estimate boot_mean        bias std_error       mse coverage
#> 1 (Intercept) -3.473155 -3.564166 -0.09101044 0.4860021 0.2440085    0.948
#> 2        sexM  1.100743  1.123543  0.02279990 0.3799061 0.1445598    0.952
#> 3  log2(dose)  1.064214  1.092733  0.02851908 0.1363093 0.0193564    0.942
#>        lower     upper
#> 1 -4.5774052 -2.644243
#> 2  0.4128645  1.855992
#> 3  0.8449368  1.408648
```

- `bias`, `std_error` and `mse` describe the bootstrap distribution
  around the original estimate.
- `coverage` is the proportion of replicates whose own Wald interval
  contains the original estimate, that is, the estimated actual coverage
  of the nominal 95% Wald interval.
- `lower` and `upper` are bootstrap confidence limits.

Four kinds of interval are available, through
[`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md)
or the usual [`confint()`](https://rdrr.io/r/stats/confint.html)
generic:

``` r

pb_confint(res, type = "percentile")
#>          term  estimate      lower     upper
#> 1 (Intercept) -3.473155 -4.5774052 -2.644243
#> 2        sexM  1.100743  0.4128645  1.855992
#> 3  log2(dose)  1.064214  0.8449368  1.408648
pb_confint(res, type = "basic")
#>          term  estimate      lower     upper
#> 1 (Intercept) -3.473155 -4.3020679 -2.368905
#> 2        sexM  1.100743  0.3454951  1.788622
#> 3  log2(dose)  1.064214  0.7197803  1.283491
pb_confint(res, type = "student")
#>          term  estimate      lower     upper
#> 1 (Intercept) -3.473155 -4.4667746 -2.611654
#> 2        sexM  1.100743  0.4337107  1.828804
#> 3  log2(dose)  1.064214  0.8009168  1.324353
confint(res, level = 0.9, type = "normal")
#>                    5 %      95 %
#> (Intercept) -4.1815471 -2.582743
#> sexM         0.4530536  1.702833
#> log2(dose)   0.8114861  1.259904
```

The studentised (bootstrap-t) interval, `type = "student"`, scales every
replicate by its own standard error. It is the most accurate of the four
when standard errors are estimated reliably; for a normal linear model
it reproduces the exact t interval, which the percentile interval does
not.

### Plots

[`pb_plot_estimates()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_estimates.md)
shows the bootstrap distributions:

``` r

pb_plot_estimates(res)
```

![Histograms of the bootstrap estimates of each coefficient, with the
original estimate marked by a dashed
line.](parametricboot_files/figure-html/plot-estimates-1.png)

[`pb_plot_diagnostics()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_diagnostics.md)
helps to judge whether `n` is large enough. The running mean should have
settled down by the right-hand edge of the plot.

``` r

pb_plot_diagnostics(res, parameter = "log2(dose)")
```

![Bootstrap estimates of the log-dose slope plotted against replicate
number, with their running mean settling just above the dashed line at
the original
estimate.](parametricboot_files/figure-html/plot-diagnostics-1.png)

All plots are ordinary ‘ggplot2’ objects, and
[`pb_tidy()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_tidy.md)
returns the replicates in long format if you prefer to build your own.

``` r

head(pb_tidy(res))
#>   replicate        term   estimate
#> 1         1 (Intercept) -3.1209121
#> 2         1        sexM  1.0047507
#> 3         1  log2(dose)  0.9303634
#> 4         2 (Intercept) -3.7778887
#> 5         2        sexM  0.8279962
#> 6         2  log2(dose)  1.2053207
```

### Predictions

[`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md)
returns one column of predictions per replicate; extra arguments go to
[`predict()`](https://rdrr.io/r/stats/predict.html).

``` r

new_moths <- data.frame(sex = c("M", "F"), dose = 8)
preds <- pb_predict_boot(res, new_moths, type = "response")
dim(preds)
#> [1]   2 500
t(apply(preds, 1, quantile, probs = c(0.025, 0.5, 0.975)))
#>        2.5%       50%     97.5%
#> 1 0.5864280 0.6950555 0.8019143
#> 2 0.3161773 0.4301403 0.5545194
```

[`pb_plot_predictions()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_predictions.md)
does this for a whole grid and plots the result:

``` r

males <- data.frame(sex = "M", dose = seq(1, 32, length.out = 100))
pb_plot_predictions(res, males, x = "dose", type = "response")
```

![Predicted probability of death for male moths against dose, with a
shaded 95 percent bootstrap
band.](parametricboot_files/figure-html/plot-predictions-1.png)

## When refits misbehave

Refits that throw an error are dropped, and refits that raise warnings
are counted rather than printed one by one. Both are reported in a
single warning, and the second kind deserves attention. Consider a
logistic regression on the 32 rows of `mtcars`:

``` r

small <- glm(vs ~ mpg, data = mtcars, family = binomial())
res_small <- pb_simulate(small, n = 500, seed = 2025)
#> Warning: 6 of 500 bootstrap refits produced warnings (for example convergence
#> problems).
```

In a few of the simulated data sets the two groups are perfectly
separated by `mpg`. The maximum likelihood estimate does not exist for
such data, and [`glm()`](https://rdrr.io/r/stats/glm.html) returns
whatever huge value the iterations stopped at. A handful of these
replicates dominates every mean and standard deviation:

``` r

pb_key_stats(res_small)[c("term", "estimate", "bias", "std_error")]
#>          term   estimate       bias std_error
#> 1 (Intercept) -8.8330726 -4.9004163 44.752399
#> 2         mpg  0.4304135  0.2487127  2.278504
```

[`pb_drop_warned()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_drop_warned.md)
excludes the replicates that raised warnings:

``` r

clean <- pb_drop_warned(res_small)
clean
#> <pb_boot> Parametric bootstrap
#>   Model:      glm (binomial)
#>   Replicates: 500 (6 dropped)
#>   Terms:      (Intercept), mpg
pb_key_stats(clean)[c("term", "estimate", "bias", "std_error")]
#>          term   estimate        bias std_error
#> 1 (Intercept) -8.8330726 -1.80982691 4.4722676
#> 2         mpg  0.4304135  0.09165097 0.2235875
```

This reveals the genuine, and substantial, small-sample bias of logistic
regression: both coefficients are overestimated in absolute value by
about a fifth. Two caveats apply.

- The cleaned summaries are conditional on the fit being well behaved.
  Report the proportion of dropped replicates with them.
- Percentile intervals are far less sensitive than means: a quantile
  registers that a few replicates were extreme, but not by how much.
  They do not need this treatment, and are arguably more honest without
  it:

``` r

pb_confint(res_small)
#>          term   estimate       lower     upper
#> 1 (Intercept) -8.8330726 -25.2280569 -4.829614
#> 2         mpg  0.4304135   0.2393271  1.296134
pb_confint(clean)
#>          term   estimate       lower     upper
#> 1 (Intercept) -8.8330726 -23.1226342 -4.823974
#> 2         mpg  0.4304135   0.2388539  1.131722
```

The studentised interval is even less affected, because a separated
refit combines a huge estimate with an even larger standard error, so
that its studentised value is unremarkable:

``` r

pb_confint(res_small, type = "student")
#>          term   estimate       lower      upper
#> 1 (Intercept) -8.8330726 -15.3430659 -4.3564960
#> 2         mpg  0.4304135   0.2003446  0.7405796
pb_confint(clean, type = "student")
#>          term   estimate       lower      upper
#> 1 (Intercept) -8.8330726 -15.3572589 -4.3549009
#> 2         mpg  0.4304135   0.2002567  0.7418482
```

Replicates are never dropped automatically, because not every warning
signals a useless fit. `res$warned` flags the affected replicates so
that you can inspect `res$replicates` before deciding.

## Mixed models

For ‘lme4’ models, new random effects are drawn for every replicate,
exactly as
[`lme4::bootMer()`](https://rdrr.io/pkg/lme4/man/bootMer.html) does, and
the variance components are tracked alongside the fixed effects.
Refitting mixed models is slow, so this is where
[`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md)
pays off: it takes the same arguments as
[`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md),
plus `workers`, and returns an identical result for a given `seed`.

``` r

cbpp <- lme4::cbpp
gm <- lme4::glmer(
  cbind(incidence, size - incidence) ~ period + (1 | herd),
  data = cbpp, family = binomial()
)

res_gm <- pb_simulate(gm, n = 100, seed = 1)
# Equivalent, on two cores: pb_parallel(gm, n = 100, workers = 2, seed = 1)

pb_summary_table(res_gm)
#>                  term   estimate  boot_mean          bias std_error        mse
#> 1         (Intercept) -1.3983429 -1.4082260 -0.0098830876 0.2281372 0.05162379
#> 2             period2 -0.9919250 -0.9926646 -0.0007395901 0.2867139 0.08138338
#> 3             period3 -1.1282162 -1.1266335  0.0015827549 0.3720195 0.13701701
#> 4             period4 -1.5797454 -1.6396247 -0.0598793034 0.4260859 0.18331925
#> 5 sd_(Intercept)|herd  0.6420699  0.6107782 -0.0312917202 0.2034181 0.04194432
#>   coverage     lower      upper
#> 1     0.96 -1.831125 -0.9797858
#> 2     0.97 -1.612817 -0.5969268
#> 3     0.94 -1.920486 -0.5743643
#> 4     0.96 -2.608564 -0.9305711
#> 5       NA  0.303524  1.1167249
```

The last row is the standard deviation of the herd effects, named as
‘lme4’ names it in `confint(gm, oldNames = FALSE)`; correlations appear
as `cor_...` and the residual standard deviation of a linear mixed model
as `sigma`. Variance components are where Wald-type inference is
weakest, and ‘lme4’ does not even report standard errors for them. That
is why their `coverage` is `NA`, and why studentised intervals are not
available for these rows. The bootstrap shows that the herd standard
deviation is underestimated (its `bias` is negative; with 1500
replicates instead of the 100 used here to keep this vignette fast, it
settles at about 10% of the estimate). This is a well-known property of
maximum likelihood with few groups, here 15 herds:

``` r

pb_plot_estimates(res_gm, parameter = "sd_(Intercept)|herd")
```

![Histogram of the bootstrap estimates of the herd standard deviation,
centred slightly below the original estimate marked by a dashed
line.](parametricboot_files/figure-html/glmer-variance-1.png)

To test whether a variance component is needed at all, see
[`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md)
below. Pass `re.form = NA` to
[`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md)
for population-level predictions.

## Cox models

A Cox model leaves the baseline hazard and the censoring mechanism
unspecified, so there is no fully parametric model to simulate from. For
`coxph` fits,
[`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
uses the model-based resampling algorithm of Davison and Hinkley (1997,
Algorithm 7.3):

- failure times are drawn from the fitted survivor function
  $`\hat S_0(t)^{\exp(x^\top\hat\beta)}`$, with $`\hat S_0`$ based on
  the Breslow estimate of the baseline hazard;
- subjects who were censored keep their censoring time, and the others
  get a censoring time drawn from the Kaplan-Meier estimate of the
  censoring distribution, conditional on exceeding their observed time.

In a model with
[`strata()`](https://rdrr.io/pkg/survival/man/strata.html), each stratum
has its own baseline hazard, censoring distribution and end of
follow-up. Only right-censored, unweighted models are supported, without
`tt()`, penalised or
[`frailty()`](https://rdrr.io/pkg/survival/man/frailty.html) terms,
strata-by-covariate interactions or
[`cluster()`](https://rdrr.io/pkg/survival/man/cluster.html).

``` r

library(survival)
cox <- coxph(Surv(time, status) ~ age + sex + ph.ecog, data = lung)

res_cox <- pb_simulate(cox, n = 200, seed = 1, keep_fits = FALSE)
pb_summary_table(res_cox)
#>      term    estimate   boot_mean          bias   std_error          mse
#> 1     age  0.01106676  0.01134408  0.0002773194 0.008398651 7.026156e-05
#> 2     sex -0.55261240 -0.55626155 -0.0036491495 0.182379304 3.310922e-02
#> 3 ph.ecog  0.46372848  0.47315099  0.0094225131 0.108767357 1.185997e-02
#>   coverage        lower       upper
#> 1    0.970 -0.005943956  0.02515576
#> 2    0.935 -0.953891755 -0.20473691
#> 3    0.945  0.249111034  0.68135323
```

Here the bootstrap standard errors are close to the partial-likelihood
ones, shown below, and the Wald intervals have close to nominal
coverage, which is reassuring. `keep_fits = FALSE` stores only the
estimates, which saves memory when you do not need predictions.

``` r

sqrt(diag(vcov(cox)))
#>         age         sex     ph.ecog 
#> 0.009267411 0.167739054 0.113577266
```

## Testing nested models

[`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md)
is the parametric bootstrap version of the likelihood-ratio test. It
simulates from the fitted *null* model, refits both models to every
simulated response, and compares the observed statistic with the
resulting reference distribution rather than with a chi-squared
distribution.

Does the effect of dose differ between the sexes?

``` r

separate <- update(fit, . ~ sex * log2(dose))
pb_lrt(fit, separate, n = 500, seed = 2025)
#> <pb_lrt> Parametric bootstrap likelihood-ratio test
#>   Null:        cbind(dead, n - dead) ~ sex + log2(dose)
#>   Alternative: cbind(dead, n - dead) ~ sex + log2(dose) + sex:log2(dose)
#>   Replicates:  500
#>   Statistic:   1.76 on 1 df
#> 
#>                          p.value
#> Chi-squared (asymptotic)   0.184
#> Bartlett-corrected         0.211
#> Parametric bootstrap        0.23
```

With only 12 observations the chi-squared p-value is somewhat too small,
as is typical, though the conclusion is the same here. For the normal
linear model, where the exact answer is known, the bootstrap p-value
converges to that of the F test.

The difference becomes dramatic when the null hypothesis lies on the
boundary of the parameter space, as when testing whether a variance
component is zero. The models may be of different classes, so the null
can simply be the model without the random effect:

``` r

dye <- lme4::Dyestuff
no_batch <- lm(Yield ~ 1, data = dye)
batch <- lme4::lmer(Yield ~ 1 + (1 | Batch), data = dye)

test <- pb_lrt(no_batch, batch, n = 500, seed = 2025)
#> Refitting REML fits by maximum likelihood, as likelihood-ratio tests require.
test
#> <pb_lrt> Parametric bootstrap likelihood-ratio test
#>   Null:        Yield ~ 1
#>   Alternative: Yield ~ 1 + (1 | Batch)
#>   Replicates:  500
#>   Statistic:   5.4 on 1 df
#> 
#>                           p.value
#> Chi-squared (asymptotic)  0.02010
#> Bartlett-corrected       1.06e-06
#> Parametric bootstrap      0.00599
```

REML fits are refitted by maximum likelihood, which likelihood-ratio
tests require. The chi-squared p-value is more than three times too
large.
[`pb_plot_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_lrt.md)
shows why: under the null hypothesis the estimated batch variance, and
with it the statistic, is exactly zero in about two thirds of samples,
which no chi-squared distribution can reproduce. The Bartlett correction
only rescales the chi-squared distribution, so it cannot help either,
and here makes matters worse.

``` r

pb_plot_lrt(test)
```

![Histogram of the bootstrap likelihood-ratio statistics with a very
tall bar at zero, more than twice as high as the chi-squared
approximation drawn in red, and the observed statistic of 5.4 marked far
in the right tail.](parametricboot_files/figure-html/lrt-plot-1.png)

## Comparing models that are not nested

[`pb_compare_models()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_compare_models.md)
bootstraps several models and reports the sampling variability of a fit
criterion under each of them. Here, three link functions for the
dose-response curve:

``` r

links <- list(
  logit = fit,
  probit = update(fit, family = binomial("probit")),
  cloglog = update(fit, family = binomial("cloglog"))
)
pb_compare_models(links, n = 200, seed = 1)
#>     model observed boot_mean  boot_sd    lower    upper
#> 1   logit 42.86747  46.74309 4.048691 39.84039 55.72513
#> 2  probit 41.67636  46.30737 4.274158 37.89211 53.90810
#> 3 cloglog 42.93802  45.99350 3.994673 39.22221 55.17857
```

The AIC differences between the links are about one unit, against a
sampling standard deviation (`boot_sd`) of about four: these data cannot
tell the links apart, and a difference in AIC that is small relative to
`boot_sd` should not be over-interpreted.

## Practical advice

- Use at least a few hundred replicates for standard errors and 1000 or
  more for confidence limits; check
  [`pb_plot_diagnostics()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_diagnostics.md).
- The parametric bootstrap is only as good as the model. It quantifies
  sampling variability *assuming the fitted model is right*; it does not
  detect misspecification.
  [`pb_resample()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_resample.md)
  offers simple case resampling if you want a nonparametric point of
  comparison.
- Models must be fitted with a `data` argument so that they can be
  refitted.

## References

Collett, D. (1991) *Modelling Binary Data*. Chapman & Hall.

Davison, A. C. and Hinkley, D. V. (1997) *Bootstrap Methods and their
Application*. Cambridge University Press.

Halekoh, U. and Hojsgaard, S. (2014) A Kenward-Roger approximation and
parametric bootstrap methods for tests in linear mixed models: the R
package pbkrtest. *Journal of Statistical Software*, 59(9), 1-32.
