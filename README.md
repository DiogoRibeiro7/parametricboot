# parametricboot

Utilities for automating parametric bootstrap for models fitted with `stats::glm()`, `lme4::glmer()`, or `survival::coxph()`.

## Installation

This package is under development. You can install the development version from this repository once it is built as an R package.

## Core functions

- `pb_simulate()` – run N bootstrap replicates.
- `pb_plot_estimates()` – compare empirical and bootstrap distributions.
- `pb_key_stats()` – compute bias, MSE, and coverage.
- `pb_confint()` – derive bootstrap confidence intervals.
- `pb_predict_boot()` – generate predictions from bootstrap fits.
- `pb_summary_table()` – summarize statistics and intervals in a tidy table.
- `pb_plot_predictions()` – visualize predictive distributions for new data.
- `pb_compare_models()` – bootstrap and compare multiple models.
- `pb_plot_diagnostics()` – visualize diagnostic traces.
- `pb_resample()` – helper to resample rows from a data frame.
- `pb_parallel()` – run simulations in parallel.
- `pb_tidy()` – convert bootstrap estimates to tidy format.
