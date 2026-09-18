#' Plot bootstrap diagnostics
#'
#' Draws, for each coefficient, the running mean of the bootstrap estimates
#' against the number of replicates. The running mean settles down once enough
#' replicates have been drawn, so a curve that is still drifting at the right
#' edge suggests increasing `n`. The grey points are the individual estimates
#' and the dashed line is the original estimate; a persistent gap between the
#' curve and the dashed line is the bootstrap estimate of bias.
#'
#' @inheritParams pb_plot_estimates
#'
#' @return A `ggplot` object.
#'
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_simulate(fit, n = 100, seed = 1)
#' pb_plot_diagnostics(res)
#' @export
pb_plot_diagnostics <- function(results, parameter = NULL) {
  pb_check_boot(results)
  parameter <- pb_check_terms(results, parameter)

  boot <- pb_tidy(results)
  boot <- boot[boot$term %in% parameter & !is.na(boot$estimate), , drop = FALSE]
  boot$term <- factor(boot$term, levels = parameter)
  boot$running_mean <- stats::ave(
    boot$estimate, boot$term,
    FUN = function(x) cumsum(x) / seq_along(x)
  )
  observed <- data.frame(
    term = factor(parameter, levels = parameter),
    estimate = unname(pb_coef(results$original)[parameter])
  )

  ggplot2::ggplot(boot, ggplot2::aes(x = .data$replicate)) +
    ggplot2::geom_point(ggplot2::aes(y = .data$estimate), colour = "grey70", size = 0.8) +
    ggplot2::geom_hline(
      data = observed, ggplot2::aes(yintercept = .data$estimate),
      linetype = "dashed"
    ) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$running_mean),
      colour = "steelblue", linewidth = 0.8
    ) +
    ggplot2::facet_wrap(ggplot2::vars(.data$term), scales = "free_y") +
    ggplot2::labs(
      title = "Bootstrap diagnostics",
      subtitle = "Points: replicate estimates. Line: running mean. Dashed: original estimate",
      x = "Replicate", y = "Estimate"
    ) +
    ggplot2::theme_minimal()
}
