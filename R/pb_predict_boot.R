#' Predict with bootstrap uncertainty
#'
#' Computes predictions from every refitted bootstrap model.
#'
#' @inheritParams pb_confint
#' @param newdata Optional data frame to predict for. If `NULL`, predictions
#'   are made for the observations used to fit the model.
#' @param ... Additional arguments passed to [stats::predict()], such as
#'   `type = "response"`, or `re.form = NA` for population-level predictions
#'   from mixed models.
#'
#' @return A numeric matrix with one row per observation and one column per
#'   successful bootstrap replicate.
#'
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_simulate(fit, n = 50, seed = 1)
#'
#' new_cars <- data.frame(mpg = c(15, 20, 25))
#' preds <- pb_predict_boot(res, new_cars, type = "response")
#' dim(preds)
#'
#' # 95% percentile intervals for the predicted probabilities
#' t(apply(preds, 1, quantile, probs = c(0.025, 0.975)))
#' @export
pb_predict_boot <- function(results, newdata = NULL, ...) {
  pb_check_boot(results)
  fits <- pb_fits(results)
  if (!is.null(newdata) && !is.data.frame(newdata)) {
    pb_abort("`newdata` must be a data frame or `NULL`.")
  }

  preds <- lapply(fits, function(fit) {
    if (is.null(newdata)) {
      stats::predict(fit, ...)
    } else {
      stats::predict(fit, newdata = newdata, ...)
    }
  })
  preds <- do.call(cbind, preds)
  colnames(preds) <- NULL
  preds
}
