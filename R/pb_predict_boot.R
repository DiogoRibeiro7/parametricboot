#' Predict with bootstrap uncertainty
#'
#' @param results Output from `pb_simulate()`.
#' @param newdata New data for prediction.
#' @return A matrix of predictions where each column is a bootstrap replicate.
#' @export
pb_predict_boot <- function(results, newdata = NULL) {
  if (!inherits(results, "pb_boot")) {
    stop("results must come from pb_simulate()")
  }
  if (is.null(newdata)) {
    newdata <- model.frame(results$original)
  }
  preds <- sapply(results$replicates, stats::predict, newdata = newdata)
  preds
}
