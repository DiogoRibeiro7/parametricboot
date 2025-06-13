#' Plot empirical vs bootstrap distributions
#'
#' @param results Output from `pb_simulate()`.
#' @param parameter Parameter name to plot.
#' @return A ggplot object.
#' @examples
#' # pb_plot_estimates(res)
#' @export
pb_plot_estimates <- function(results, parameter) {
  if (!inherits(results, "pb_boot")) {
    stop("results must come from pb_simulate()")
  }

  boot_est <- sapply(results$replicates, function(mod) stats::coef(mod)[parameter])
  emp_est <- stats::coef(results$original)[parameter]

  df <- data.frame(estimate = c(emp_est, boot_est),
                   type = c("empirical", rep("bootstrap", length(boot_est))))

  ggplot2::ggplot(df, ggplot2::aes(x = estimate, fill = type)) +
    ggplot2::geom_density(alpha = 0.4) +
    ggplot2::labs(title = paste("Bootstrap Distribution for", parameter),
                  x = "Estimate", fill = "Type") +
    ggplot2::theme_minimal()
}
