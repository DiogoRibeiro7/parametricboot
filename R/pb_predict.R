#' Predict using retained bootstrap refits or cached predictions
#'
#' `pb_predict()` is the concise, preferred spelling of
#' [pb_predict_boot()]. Both names use exactly the same implementation and
#' return the same matrix. The longer name remains supported for backwards
#' compatibility.
#'
#' @inheritParams pb_predict_boot
#' @return A numeric matrix, with one row per observation and one column
#'   per successful bootstrap prediction.
#' @seealso [pb_predict_boot()], [pb_predict_interval()]
#' @examples
#' fit <- stats::lm(mpg ~ wt + hp, data = mtcars)
#' res <- pb_simulate(fit, n = 20, seed = 1)
#' pb_predict(res, mtcars[1:2, c("wt", "hp")])
#' @export
pb_predict <- function(results, newdata = NULL, ...) {
  pb_predict_boot(results, newdata = newdata, ...)
}
