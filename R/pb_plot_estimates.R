#' Plot the bootstrap distribution of the estimates
#'
#' Draws a histogram of the bootstrap estimates of each coefficient, with the
#' original estimate marked by a vertical line.
#'
#' @inheritParams pb_confint
#' @param parameter Character vector of coefficient names to plot. The default,
#'   `NULL`, plots all of them.
#' @param bins Number of histogram bins.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_simulate(fit, n = 100, seed = 1)
#'
#' pb_plot_estimates(res)
#' pb_plot_estimates(res, parameter = "mpg")
#' @export
pb_plot_estimates <- function(results, parameter = NULL, bins = 30) {
  pb_check_boot(results)
  parameter <- pb_check_terms(results, parameter)

  boot <- pb_tidy(results)
  boot <- boot[boot$term %in% parameter, , drop = FALSE]
  boot$term <- factor(boot$term, levels = parameter)
  observed <- data.frame(
    term = factor(parameter, levels = parameter),
    estimate = unname(pb_coef(results$original)[parameter])
  )

  ggplot2::ggplot(boot, ggplot2::aes(x = .data$estimate)) +
    ggplot2::geom_histogram(bins = bins, fill = "steelblue", colour = "white", alpha = 0.8) +
    ggplot2::geom_vline(
      data = observed, ggplot2::aes(xintercept = .data$estimate),
      linetype = "dashed", linewidth = 0.8
    ) +
    ggplot2::facet_wrap(ggplot2::vars(.data$term), scales = "free") +
    ggplot2::labs(
      title = "Bootstrap distribution of the estimates",
      subtitle = "Dashed line: original estimate",
      x = "Estimate", y = "Replicates"
    ) +
    ggplot2::theme_minimal()
}
