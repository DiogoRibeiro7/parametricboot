#' Resample a data frame with replacement
#'
#' @param data Data frame to resample.
#' @param size Number of rows to sample (defaults to nrow(data)).
#' @return A resampled data frame.
#' @export
pb_resample <- function(data, size = nrow(data)) {
  data[sample(seq_len(nrow(data)), size = size, replace = TRUE), , drop = FALSE]
}
