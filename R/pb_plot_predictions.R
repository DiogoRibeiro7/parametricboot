#' Plot predictions with bootstrap intervals
#'
#' Plots the predictions of the original model for `newdata` together with
#' percentile intervals computed from the bootstrap refits.
#'
#' @inheritParams pb_predict_boot
#' @param newdata Data frame to predict for.
#' @param x Name of the column of `newdata` to put on the horizontal axis. A
#'   numeric column gives a line with a ribbon; any other column, or the
#'   default `NULL` (row number), gives points with error bars.
#' @param level Level of the bootstrap percentile interval.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_simulate(fit, n = 100, seed = 1)
#'
#' new_cars <- data.frame(mpg = seq(10, 35, by = 1))
#' pb_plot_predictions(res, new_cars, x = "mpg", type = "response")
#' @export
pb_plot_predictions <- function(results, newdata, x = NULL, level = 0.95, ...) {
  pb_check_boot(results)
  level <- pb_check_level(level)
  if (!is.data.frame(newdata)) {
    pb_abort("`newdata` must be a data frame.")
  }
  if (!is.null(x) && !(is.character(x) && length(x) == 1L && x %in% names(newdata))) {
    pb_abort("`x` must be `NULL` or the name of a column of `newdata`.")
  }

  preds <- pb_predict_boot(results, newdata, ...)
  alpha <- (1 - level) / 2
  df <- data.frame(
    x = if (is.null(x)) seq_len(nrow(newdata)) else newdata[[x]],
    prediction = as.numeric(stats::predict(results$original, newdata = newdata, ...)),
    lower = apply(preds, 1, stats::quantile, probs = alpha, na.rm = TRUE, names = FALSE),
    upper = apply(preds, 1, stats::quantile, probs = 1 - alpha, na.rm = TRUE, names = FALSE)
  )

  plot <- ggplot2::ggplot(df, ggplot2::aes(x = .data$x, y = .data$prediction))
  if (!is.null(x) && is.numeric(df$x)) {
    plot <- plot +
      ggplot2::geom_ribbon(
        ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
        fill = "steelblue", alpha = 0.3
      ) +
      ggplot2::geom_line(colour = "steelblue", linewidth = 0.8)
  } else {
    plot <- plot +
      ggplot2::geom_pointrange(
        ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
        colour = "steelblue"
      )
  }

  plot +
    ggplot2::labs(
      title = "Bootstrap predictions",
      subtitle = paste0(format(100 * level), "% bootstrap percentile interval"),
      x = if (is.null(x)) "Row of newdata" else x,
      y = "Prediction"
    ) +
    ggplot2::theme_minimal()
}
