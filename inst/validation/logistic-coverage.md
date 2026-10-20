## Small-sample logistic regression coverage

Run the opt-in experiment after installing the development package:

```sh
Rscript inst/validation/logistic-coverage.R
OUTER_N=400 BOOT_N=999 Rscript inst/validation/logistic-coverage.R
```

The design fixes 24 covariates and known logistic coefficients. New Bernoulli
responses are generated independently for each outer iteration. A fresh
parametric bootstrap is used to compare Wald, percentile and studentised
intervals for the known slope.

The script records original-fit warnings, warned and failed bootstrap refits,
and method-specific numbers of evaluable intervals. Coverage is reported
*conditional on evaluability*. If separation, convergence or invalid intervals
remove observations, that conditional coverage is not unconditional coverage.
The plugin does not silently drop warned bootstrap refits. The script uses
the default inclusion rule and reports the warnings.

Defaults are illustrative and noisy, not acceptance thresholds. The outer
Monte Carlo standard error is a binomial plug-in estimate over evaluable
datasets and excludes uncertainty from the finite inner bootstrap. The
study does not validate the model under misspecification, nor does a finite
experiment establish nominal frequentist coverage in general.
