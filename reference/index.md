# Package index

## Draw bootstrap replicates

- [`pb_simulate()`](pb_simulate.md) : Run parametric bootstrap
  replicates
- [`pb_parallel()`](pb_parallel.md) : Run parametric bootstrap
  replicates in parallel
- [`pb_drop_warned()`](pb_drop_warned.md) : Drop replicates whose refit
  raised a warning

## Summarise

- [`pb_summary_table()`](pb_summary_table.md) : Summarise bootstrap
  statistics and confidence intervals

- [`pb_key_stats()`](pb_key_stats.md) : Bootstrap bias, standard error,
  MSE and coverage

- [`pb_confint()`](pb_confint.md) : Bootstrap confidence intervals

- [`pb_tidy()`](pb_tidy.md) : Convert bootstrap estimates to long format

- [`print(`*`<pb_boot>`*`)`](pb_boot-methods.md)
  [`summary(`*`<pb_boot>`*`)`](pb_boot-methods.md)
  [`confint(`*`<pb_boot>`*`)`](pb_boot-methods.md) :

  Methods for `pb_boot` objects

## Visualise

- [`pb_plot_estimates()`](pb_plot_estimates.md) : Plot the bootstrap
  distribution of the estimates
- [`pb_plot_diagnostics()`](pb_plot_diagnostics.md) : Plot bootstrap
  diagnostics
- [`pb_plot_predictions()`](pb_plot_predictions.md) : Plot predictions
  with bootstrap intervals

## Predict and compare

- [`pb_predict_boot()`](pb_predict_boot.md) : Predict with bootstrap
  uncertainty
- [`pb_compare_models()`](pb_compare_models.md) : Compare models by the
  bootstrap distribution of a fit metric

## Helpers

- [`pb_resample()`](pb_resample.md) : Resample the rows of a data frame
  with replacement
