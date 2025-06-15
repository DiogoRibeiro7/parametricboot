#' Convert bootstrap results to tidy format
#'
#' @param results Output from `pb_simulate()`.
#' @return A tidy data frame with estimates for each replicate.
#' @export
pb_tidy <- function(results) {
  if (!inherits(results, "pb_boot")) {
    stop("results must come from pb_simulate()")
  }
  boot_mat <- sapply(results$replicates, stats::coef)
  if (is.null(dim(boot_mat))) {
    boot_mat <- matrix(boot_mat, nrow = length(boot_mat))
  }
  df <- as.data.frame(t(boot_mat))
  df$replicate <- seq_len(nrow(df))
  tidyr::pivot_longer(df, -replicate, names_to = "term", values_to = "estimate")
}
