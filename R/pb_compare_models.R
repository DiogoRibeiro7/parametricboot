#' Compare models by the bootstrap distribution of a fit metric
#'
#' Runs a parametric bootstrap for each model and evaluates `metric` on the
#' original fit and on every refit. This shows how much a criterion such as
#' the AIC varies from sample to sample under each fitted model, which helps
#' to judge whether an observed difference between models is meaningful.
#'
#' @param models A non-empty list of fitted models supported by
#'   [pb_simulate()]. Names, if present, are used to label the models.
#' @param n Number of bootstrap replicates for each model.
#' @param metric A function that takes a fitted model and returns a single
#'   number, such as [stats::AIC()], [stats::BIC()] or [stats::deviance()].
#' @param level Level of the percentile interval reported for the metric.
#' @param seed Optional single number making the comparison reproducible.
#' @param ... Additional arguments passed to [pb_simulate()].
#'
#' @return A data frame with one row per model and columns `model`,
#'   `observed` (the metric of the original fit), `boot_mean`, `boot_sd`,
#'   `lower` and `upper` (summaries of the metric over the bootstrap refits).
#'
#' @examples
#' fits <- list(
#'   mpg = glm(vs ~ mpg, data = mtcars, family = binomial()),
#'   mpg_wt = glm(vs ~ mpg + wt, data = mtcars, family = binomial())
#' )
#' pb_compare_models(fits, n = 25, seed = 1)
#' @export
pb_compare_models <- function(models, n = 100, metric = stats::AIC, level = 0.95,
                              seed = NULL, ...) {
  if (!is.list(models) || length(models) == 0L || inherits(models, c("lm", "merMod", "coxph"))) {
    pb_abort("`models` must be a non-empty list of fitted models.")
  }
  if (!is.function(metric)) {
    pb_abort("`metric` must be a function of a fitted model returning a single number.")
  }
  level <- pb_check_level(level)
  alpha <- (1 - level) / 2

  labels <- names(models)
  if (is.null(labels)) {
    labels <- rep("", length(models))
  }
  unnamed <- is.na(labels) | labels == ""
  labels[unnamed] <- paste0("model_", seq_along(models))[unnamed]

  rows <- pb_with_seed(seed, lapply(models, function(model) {
    res <- pb_simulate(model, n = n, ..., keep_fits = TRUE)
    boot <- vapply(pb_fits(res), function(fit) as.numeric(metric(fit)), numeric(1))
    data.frame(
      observed = as.numeric(metric(model)),
      boot_mean = mean(boot),
      boot_sd = stats::sd(boot),
      lower = stats::quantile(boot, alpha, names = FALSE),
      upper = stats::quantile(boot, 1 - alpha, names = FALSE)
    )
  }))

  out <- cbind(data.frame(model = labels, stringsAsFactors = FALSE), do.call(rbind, rows))
  rownames(out) <- NULL
  out
}
