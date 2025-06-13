#' Compute bias, MSE and coverage
#'
#' @param results Output from `pb_simulate()`.
#' @return A data frame with statistics.
#' @examples
#' # pb_key_stats(res)
#' @export
pb_key_stats <- function(results) {
  if (!inherits(results, "pb_boot")) {
    stop("results must come from pb_simulate()")
  }

  boot_mat <- sapply(results$replicates, stats::coef)
  if (is.null(dim(boot_mat))) {
    boot_mat <- matrix(boot_mat, nrow = length(boot_mat))
  }

  emp <- stats::coef(results$original)
  bias <- rowMeans(boot_mat) - emp
  mse <- rowMeans((boot_mat - emp)^2)
  ci_low <- apply(boot_mat, 1, quantile, 0.025)
  ci_high <- apply(boot_mat, 1, quantile, 0.975)
  coverage <- emp >= ci_low & emp <= ci_high

  data.frame(term = names(emp), bias = bias, mse = mse, coverage = coverage)
}
