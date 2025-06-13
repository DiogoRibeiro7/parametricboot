# parametricboot
Automates parametric bootstrap for any model fitted via stats::glm(), lme4::glmer(), or survival::coxph().


Why it’s missing: There are bits and pieces (e.g. boot for generic bootstraps, model-specific wrappers) but no unified interface that:

Extracts the fitted model,

simulates new response vectors under the fitted distribution,

refits,

collects statistics,

plots diagnostics (histogram of estimates, CI bands, convergence failures, etc.).


Core functions:

pb_simulate() – run N bootstrap replicates.

pb_plot_estimates() – compare empirical and bootstrap distributions.

pb_key_stats() – compute bias, MSE, coverage.
