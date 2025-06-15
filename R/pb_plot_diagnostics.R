#' Plot diagnostic information for bootstrap replicates
#'
#' @param results Output from `pb_simulate()`.
#' @param parameter Parameter name for residual plot.
#' @return A ggplot object with diagnostics.
#' @export
pb_plot_diagnostics <- function(results, parameter) {
  if (!inherits(results, "pb_boot")) {
    stop("results must come from pb_simulate()")
  }
  boot_est <- sapply(results$replicates, function(m) stats::coef(m)[parameter])
  df <- data.frame(iter = seq_along(boot_est), estimate = boot_est)
  ggplot2::ggplot(df, ggplot2::aes(x = iter, y = estimate)) +
    ggplot2::geom_line() +
    ggplot2::labs(title = paste("Trace plot for", parameter), x = "Iteration", y = "Estimate") +
    ggplot2::theme_minimal()
}
