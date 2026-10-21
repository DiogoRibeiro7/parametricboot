# Mixed-effects model with few groups

Run this optional repeated-sampling experiment after installing the current
development package, `lme4` and `withr`.

```sh
Rscript inst/validation/mixed-few-groups.R
OUTER_N=100 BOOT_N=399 Rscript inst/validation/mixed-few-groups.R
```

The synthetic model has six groups and eight observations per group, with a
known fixed slope, normally distributed random intercepts and Gaussian
residuals. Every outer iteration generates *new* random effects and errors,
fits an ML random-intercept model, and computes normal-approximation Wald and
parametric-bootstrap percentile intervals for the fixed slope.

The package bootstrap simulates new random effects, corresponding to
*marginal* bootstrap inference (`lme4::bootMer(use.u = FALSE)`). This is
not the conditional `use.u = TRUE` experiment. The script deliberately does
not interpret either method as an exact small-sample confidence interval.

The results show method-specific evaluable denominators, conditional empirical
coverage and the plug-in Monte Carlo standard error over the outer draws.
Singular original fits, original fitting errors, and warned or failed inner
refits are reported separately. An unavailable interval is not counted as
a coverage failure; therefore these estimates are not unconditional coverage.

The small default simulation budget is illustrative, not suitable for firm
claims about coverage. Increase both budgets and repeat across group counts,
variance ratios and design settings before drawing substantive conclusions.
