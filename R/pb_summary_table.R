#' Summarize bootstrap statistics
#'
#' @param results Output from `pb_simulate()`.
#' @return A tidy summary table of key statistics.
#' @export
pb_summary_table <- function(results) {
  stats <- pb_key_stats(results)
  ci <- pb_confint(results)
  merge(stats, ci, by = "term")
}
