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

- [`pb_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md)
  [`print(`*`<pb_lrt>`*`)`](https://diogoribeiro7.github.io/parametricboot/reference/pb_lrt.md)
  : Parametric bootstrap likelihood-ratio test for nested models
- [`pb_plot_lrt()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_plot_lrt.md)
  : Plot the bootstrap null distribution of a likelihood-ratio statistic
- [`pb_compare_models()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_compare_models.md)
  : Compare models by the bootstrap distribution of a fit metric

## Predict

- [`pb_predict_boot()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_predict_boot.md)
  : Predict with bootstrap uncertainty

## Helpers

- [`pb_resample()`](https://diogoribeiro7.github.io/parametricboot/reference/pb_resample.md)
  : Resample the rows of a data frame with replacement
