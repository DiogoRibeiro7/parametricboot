#' Convert bootstrap estimates to long format
#'
#' @inheritParams pb_confint
#'
#' @return A data frame with one row per successful replicate and coefficient,
#'   and columns `replicate`, `term` and `estimate`. It is ready for use with
#'   'ggplot2' or 'dplyr'.
#'
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_simulate(fit, n = 50, seed = 1)
#' head(pb_tidy(res))
#' @export
pb_tidy <- function(results) {
  pb_check_boot(results)
  est <- pb_estimates(results)
  data.frame(
    replicate = rep(which(!results$failed), each = ncol(est)),
    term = rep(colnames(est), times = nrow(est)),
    estimate = as.vector(t(est)),
    stringsAsFactors = FALSE
  )
}
