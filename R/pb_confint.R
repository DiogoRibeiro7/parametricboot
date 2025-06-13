#' Bootstrap confidence intervals
#'
#' @param results Output from `pb_simulate()`.
#' @param level Confidence level between 0 and 1.
#' @return A data frame with lower and upper bounds for each parameter.
#' @export
pb_confint <- function(results, level = 0.95) {
  if (!inherits(results, "pb_boot")) {
    stop("results must come from pb_simulate()")
  }
  alpha <- (1 - level) / 2
  boot_mat <- sapply(results$replicates, stats::coef)
  if (is.null(dim(boot_mat))) {
    boot_mat <- matrix(boot_mat, nrow = length(boot_mat))
  }
  low <- apply(boot_mat, 1, quantile, alpha)
  high <- apply(boot_mat, 1, quantile, 1 - alpha)
  data.frame(term = names(low), lower = low, upper = high)
}
