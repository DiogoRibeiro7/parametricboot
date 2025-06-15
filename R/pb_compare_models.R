#' Compare multiple models using parametric bootstrap
#'
#' @param models A list of fitted models.
#' @param n Number of bootstrap replicates for each model.
#' @param metric Function to summarize each fit (default AIC).
#' @return A data frame summarizing the chosen metric for each model.
#' @export
pb_compare_models <- function(models, n = 100, metric = stats::AIC) {
  if (!is.list(models) || length(models) == 0) {
    stop("models must be a non-empty list of fitted models")
  }
  res <- lapply(models, pb_simulate, n = n)
  vals <- sapply(res, function(r) metric(r$original))
  data.frame(model = seq_along(models), metric = vals)
}
