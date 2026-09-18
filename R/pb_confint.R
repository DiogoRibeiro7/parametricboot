#' Bootstrap confidence intervals
#'
#' @details
#' Writing \eqn{\hat\theta} for the original estimate and \eqn{\theta^*} for
#' the bootstrap estimates, the intervals are
#'
#' * `"percentile"`: the \eqn{\alpha/2} and \eqn{1 - \alpha/2} quantiles of
#'   \eqn{\theta^*};
#' * `"basic"`: \eqn{2\hat\theta} minus the upper and lower percentile limits;
#' * `"normal"`: \eqn{\hat\theta - b \pm z_{1 - \alpha/2} s}, where \eqn{b} and
#'   \eqn{s} are the bootstrap estimates of bias and standard error.
#'
#' @param results A `pb_boot` object from [pb_simulate()] or [pb_parallel()].
#' @param level Confidence level, strictly between 0 and 1.
#' @param type Type of interval: `"percentile"`, `"basic"` or `"normal"`.
#'
#' @return A data frame with one row per coefficient and columns `term`,
#'   `estimate` (the original estimate), `lower` and `upper`.
#'
#' @references
#' Davison, A. C. and Hinkley, D. V. (1997) *Bootstrap Methods and their
#' Application*, chapter 5. Cambridge University Press.
#'
#' @examples
#' fit <- glm(vs ~ mpg, data = mtcars, family = binomial())
#' res <- pb_simulate(fit, n = 50, seed = 1)
#'
#' pb_confint(res)
#' pb_confint(res, level = 0.9, type = "basic")
#' @export
pb_confint <- function(results, level = 0.95, type = c("percentile", "basic", "normal")) {
  pb_check_boot(results)
  level <- pb_check_level(level)
  type <- match.arg(type)

  est <- pb_estimates(results)
  theta <- pb_coef(results$original)
  alpha <- (1 - level) / 2

  q_low <- apply(est, 2, stats::quantile, probs = alpha, na.rm = TRUE, names = FALSE)
  q_high <- apply(est, 2, stats::quantile, probs = 1 - alpha, na.rm = TRUE, names = FALSE)

  if (type == "percentile") {
    lower <- q_low
    upper <- q_high
  } else if (type == "basic") {
    lower <- 2 * theta - q_high
    upper <- 2 * theta - q_low
  } else {
    centre <- 2 * theta - colMeans(est, na.rm = TRUE)
    half <- stats::qnorm(1 - alpha) * apply(est, 2, stats::sd, na.rm = TRUE)
    lower <- centre - half
    upper <- centre + half
  }

  data.frame(
    term = names(theta),
    estimate = unname(theta),
    lower = unname(lower),
    upper = unname(upper),
    stringsAsFactors = FALSE
  )
}
