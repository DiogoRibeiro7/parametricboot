#' Bootstrap bias, standard error, MSE and coverage
#'
#' In a parametric bootstrap the fitted model plays the role of the truth, so
#' the behaviour of the estimator around the original estimate
#' \eqn{\hat\theta} estimates its behaviour around the true parameter.
#'
#' @inheritParams pb_confint
#' @param level Nominal level of the Wald intervals whose coverage is
#'   estimated.
#'
#' @return A data frame with one row per coefficient and columns
#' \describe{
#'   \item{`term`}{coefficient name.}
#'   \item{`estimate`}{original estimate \eqn{\hat\theta}.}
#'   \item{`boot_mean`}{mean of the bootstrap estimates.}
#'   \item{`bias`}{`boot_mean - estimate`.}
#'   \item{`std_error`}{standard deviation of the bootstrap estimates.}
#'   \item{`mse`}{mean squared error of the bootstrap estimates around
#'     `estimate`.}
#'   \item{`coverage`}{proportion of replicates whose Wald interval
#'     (estimate plus or minus a normal quantile times the standard error)
#'     contains `estimate`. Values far from `level` indicate that the usual
#'     Wald intervals are unreliable for this model. It is `NA` for parameters
#'     without a standard error, such as the variance components of mixed
#'     models.}
#' }
#'
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_simulate(fit, n = 50, seed = 1)
#' pb_key_stats(res)
#' @export
pb_key_stats <- function(results, level = 0.95) {
  pb_check_boot(results)
  level <- pb_check_level(level)

  est <- pb_estimates(results)
  se <- results$std_errors[!results$failed, , drop = FALSE]
  theta <- pb_coef(results$original)
  centred <- sweep(est, 2, theta)

  boot_mean <- colMeans(est, na.rm = TRUE)
  z <- stats::qnorm(1 - (1 - level) / 2)
  covered <- abs(centred) <= z * se
  coverage <- colMeans(covered, na.rm = TRUE)
  coverage[is.nan(coverage)] <- NA_real_

  data.frame(
    term = names(theta),
    estimate = unname(theta),
    boot_mean = unname(boot_mean),
    bias = unname(boot_mean - theta),
    std_error = unname(apply(est, 2, stats::sd, na.rm = TRUE)),
    mse = unname(colMeans(centred^2, na.rm = TRUE)),
    coverage = unname(coverage),
    stringsAsFactors = FALSE
  )
}
