#' Plot the bootstrap null distribution of a likelihood-ratio statistic
#'
#' Draws a histogram of the bootstrap statistics from [pb_lrt()] and overlays
#' the counts expected under the chi-squared approximation, with the observed
#' statistic marked by a vertical line. Where the bars and the line disagree,
#' the asymptotic p-value cannot be trusted; the bootstrap p-value is the
#' share of the bars at or beyond the vertical line.
#'
#' @param test A `pb_lrt` object from [pb_lrt()].
#' @param bins Number of histogram bins.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' budworm <- data.frame(
#'   sex = rep(c("M", "F"), each = 6),
#'   dose = rep(c(1, 2, 4, 8, 16, 32), times = 2),
#'   dead = c(1, 4, 9, 13, 18, 20, 0, 2, 6, 10, 12, 16),
#'   n = 20
#' )
#' common <- glm(cbind(dead, n - dead) ~ sex + log2(dose), data = budworm, family = binomial())
#' separate <- update(common, . ~ sex * log2(dose))
#'
#' test <- pb_lrt(common, separate, n = 200, seed = 1)
#' pb_plot_lrt(test)
#' @export
pb_plot_lrt <- function(test, bins = 30) {
  if (!inherits(test, "pb_lrt")) {
    pb_abort("`test` must be a 'pb_lrt' object created by `pb_lrt()`.")
  }
  bins <- pb_check_count(bins, "bins")

  valid <- test$reference[!test$failed]
  upper <- 1.02 * max(valid, test$statistic, stats::qchisq(0.99, test$df))
  breaks <- seq(0, upper, length.out = bins + 1L)
  bars <- data.frame(
    statistic = (breaks[-1] + breaks[-length(breaks)]) / 2,
    count = as.vector(table(cut(valid, breaks, include.lowest = TRUE))),
    expected = length(valid) * diff(stats::pchisq(breaks, test$df))
  )

  ggplot2::ggplot(bars, ggplot2::aes(x = .data$statistic)) +
    ggplot2::geom_col(
      ggplot2::aes(y = .data$count),
      width = upper / bins, fill = "steelblue", colour = "white", alpha = 0.8
    ) +
    ggplot2::geom_line(ggplot2::aes(y = .data$expected), colour = "firebrick", linewidth = 0.8) +
    ggplot2::geom_point(ggplot2::aes(y = .data$expected), colour = "firebrick", size = 1.2) +
    ggplot2::geom_vline(xintercept = test$statistic, linetype = "dashed", linewidth = 0.8) +
    ggplot2::labs(
      title = "Null distribution of the likelihood-ratio statistic",
      subtitle = paste0(
        "Bars: bootstrap. Red line: chi-squared approximation (", test$df,
        " df). Dashed line: observed statistic"
      ),
      x = "Likelihood-ratio statistic", y = "Replicates"
    ) +
    ggplot2::theme_minimal()
}
