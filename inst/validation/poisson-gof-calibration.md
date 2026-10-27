# Calibration of Poisson goodness-of-fit tests

Run the optional experiment after installing `parametricboot` and `withr`:

```sh
Rscript inst/validation/poisson-gof-calibration.R
OUTER_N=400 BOOT_N=999 Rscript inst/validation/poisson-gof-calibration.R
```

This fixed-design experiment compares two data-generating mechanisms:
a correctly specified Poisson regression and a zero-inflated count process
with a structural-zero probability of 0.25. Both are fitted using Poisson
regression. Each outer sample uses a newly fitted model and a separate
parametric bootstrap test for excess zeros (`statistic = "zeros"`,
`tail = "greater"`).

The reported rejection rate under the null estimates the test's type-I
error at the chosen significance level. Under zero inflation, it estimates
power against *this particular alternative*. The experiment also reports
outer Monte Carlo standard errors, evaluable denominators, and mean counts
of successful bootstrap refits.

The default simulation budget is illustrative, not sufficient to establish
calibration. Discrete statistics, fitted nuisance parameters, Monte Carlo
p-value resolution, and selective refit failures all affect interpretation.
The add-one bootstrap p-value is not a posterior probability of the null
model. No claim of uniform calibration or power across count models follows
from these results.
