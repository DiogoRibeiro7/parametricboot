# Cox model coverage with independent censoring

Run after installing the development version of the package and its suggested
`survival` dependency:

```sh
Rscript inst/validation/survival-coverage.R
OUTER_N=150 BOOT_N=399 Rscript inst/validation/survival-coverage.R
```

This repeated-sampling experiment generates a new binary covariate, event time
from an exponential proportional-hazards law, and an independent exponential
censoring time for each subject. The observed follow-up is the minimum of
the two times, with an event indicator recording the winner.

Each outer dataset receives a new Cox partial-likelihood fit, and a separate
model-based bootstrap. Wald and bootstrap percentile intervals target the
known log hazard ratio, rather than the estimated coefficient. The package's
survival bootstrap uses an estimated baseline hazard and censoring mechanism;
it is not the same as drawing directly from the known exponential law.

The report distinguishes original-fit failures, complete bootstrap failures,
inner warned/failed refits, censoring fraction, and method-specific
evaluable interval denominators. Empirical coverage is conditional on
evaluability; missing intervals are not silently counted as misses.

The defaults are deliberately small and noisy. The reported binomial
Monte Carlo standard errors reflect independent outer replications, not
finite inner bootstrap uncertainty. The experiment assumes non-informative
censoring and a correctly specified proportional-hazards model. It neither
validates informative censoring nor establishes universal Cox-model coverage.
