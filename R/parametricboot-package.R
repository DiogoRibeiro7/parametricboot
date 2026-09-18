#' parametricboot: Parametric Bootstrap for Fitted Regression Models
#'
#' Automates the parametric bootstrap for models fitted with [stats::lm()],
#' [stats::glm()], [lme4::lmer()], [lme4::glmer()] and [survival::coxph()].
#'
#' @section Workflow:
#' 1. Fit a model as usual.
#' 2. Draw bootstrap replicates with [pb_simulate()], or [pb_parallel()] when
#'    a single refit is slow.
#' 3. Summarise them: [pb_summary_table()], [pb_key_stats()], [pb_confint()]
#'    and [pb_tidy()] for tables; [pb_plot_estimates()] and
#'    [pb_plot_diagnostics()] for plots. If some refits misbehaved, see
#'    [pb_drop_warned()].
#' 4. Propagate the uncertainty to predictions with [pb_predict_boot()] and
#'    [pb_plot_predictions()], or to model comparisons with
#'    [pb_compare_models()].
#'
#' @keywords internal
#' @importFrom ggplot2 .data
"_PACKAGE"
