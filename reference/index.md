# Package index

## Draw bootstrap replicates

- [`pb_simulate()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_simulate.md)
  : Run parametric bootstrap replicates
- [`pb_parallel()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_parallel.md)
  : Run parametric bootstrap replicates in parallel
- [`pb_drop_warned()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_drop_warned.md)
  : Drop replicates whose refit raised a warning

## Summarise

- [`pb_summary_table()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_summary_table.md)
  : Summarise bootstrap statistics and confidence intervals

- [`pb_key_stats()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_key_stats.md)
  : Bootstrap bias, standard error, MSE and coverage

- [`pb_confint()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint.md)
  : Bootstrap confidence intervals

- [`pb_mc_error()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_mc_error.md)
  : Monte Carlo errors of bootstrap bias and standard error

- [`pb_confint_mc_error()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_confint_mc_error.md)
  : Monte Carlo precision of bootstrap confidence interval limits

- [`pb_tidy()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_tidy.md)
  : Convert bootstrap estimates to long format

- [`print(`*`<pb_boot>`*`)`](https://diogoribeiro7.github.io/parametricboot/reference/pb_boot-methods.md)
  [`summary(`*`<pb_boot>`*`)`](https://diogoribeiro7.github.io/parametricboot/reference/pb_boot-methods.md)
  [`confint(`*`<pb_boot>`*`)`](https://diogoribeiro7.github.io/parametricboot/reference/pb_boot-methods.md)
  :

  Methods for `pb_boot` objects

## Visualise

- [`pb_plot_estimates()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_estimates.md)
  : Plot the bootstrap distribution of the estimates
- [`pb_plot_diagnostics()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_diagnostics.md)
  : Plot bootstrap diagnostics
- [`pb_plot_predictions()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_predictions.md)
  : Plot predictions with bootstrap intervals

## Test and compare models

- [`pb_gof()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_gof.md)
  : Parametric-bootstrap goodness-of-fit test
- [`pb_gof_mc_error()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_gof_mc_error.md)
  : Monte Carlo uncertainty of a bootstrap goodness-of-fit p-value
- [`pb_plot_gof()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_gof.md)
  : Plot a simulated goodness-of-fit reference distribution
- [`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md)
  [`print(`*`<pb_lrt>`*`)`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md)
  : Parametric bootstrap likelihood-ratio test for nested models
- [`pb_lrt_mc_error()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt_mc_error.md)
  : Monte Carlo uncertainty for a parametric bootstrap likelihood-ratio
  p-value
- [`pb_plot_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_lrt.md)
  : Plot the bootstrap null distribution of a likelihood-ratio statistic
- [`pb_compare_models()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_compare_models.md)
  : Compare models by the bootstrap distribution of a fit metric

## Predict

- [`pb_predict()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict.md)
  : Predict using retained bootstrap refits or cached predictions
- [`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md)
  : Predict with bootstrap uncertainty
- [`pb_predict_interval()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_interval.md)
  : Prediction intervals for new observations
- [`pb_predict_observations()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_observations.md)
  : Simulate future observations from parametric bootstrap refits
- [`pb_predict_variance()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_variance.md)
  : Decompose model-conditional predictive variance

## Helpers

- [`pb_resample()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_resample.md)
  : Resample the rows of a data frame with replacement
