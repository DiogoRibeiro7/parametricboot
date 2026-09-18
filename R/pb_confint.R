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
#'   \eqn{s} are the bootstrap estimates of bias and standard error;
#' * `"student"`: the studentised or bootstrap-t interval,
#'   \eqn{(\hat\theta - \hat s\, q_{1 - \alpha/2},\ \hat\theta - \hat s\, q_{\alpha/2})},
#'   where \eqn{\hat s} is the standard error of the original fit and
#'   \eqn{q} are quantiles of the studentised bootstrap estimates
#'   \eqn{(\theta^* - \hat\theta) / s^*}, each replicate being scaled by its own
#'   standard error \eqn{s^*}.
#'
#' The studentised interval replaces the normal quantiles of the Wald interval
#' by bootstrap ones. It is the most accurate of the four when the standard
#' error is estimated reliably (its coverage error is of smaller order in the
#' sample size), and it is exact for the normal linear model, where it
#' reproduces the usual t interval. Scaling each replicate by its own standard
#' error also makes it insensitive to degenerate refits, such as perfectly
#' separated logistic regressions, whose huge estimates come with huge
#' standard errors. It is not invariant to reparametrisation, and it needs
#' more replicates than the percentile interval because it relies on the tails
#' of a ratio. It is not available for parameters without a standard error,
#' such as the variance components of mixed models: their limits are `NA`,
#' with a warning.
#'
#' @param results A `pb_boot` object from [pb_simulate()] or [pb_parallel()].
#' @param level Confidence level, strictly between 0 and 1.
#' @param type Type of interval: `"percentile"`, `"basic"`, `"normal"` or
#'   `"student"`.
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
#' pb_confint(res, type = "student")
#' @export
pb_confint <- function(results, level = 0.95,
                       type = c("percentile", "basic", "normal", "student")) {
  pb_check_boot(results)
  level <- pb_check_level(level)
  type <- match.arg(type)

  est <- pb_estimates(results)
  theta <- pb_coef(results$original)
  alpha <- (1 - level) / 2

  q_low <- pb_col_quantile(est, alpha)
  q_high <- pb_col_quantile(est, 1 - alpha)

  if (type == "percentile") {
    lower <- q_low
    upper <- q_high
  } else if (type == "basic") {
    lower <- 2 * theta - q_high
    upper <- 2 * theta - q_low
  } else if (type == "normal") {
    centre <- 2 * theta - colMeans(est, na.rm = TRUE)
    half <- stats::qnorm(1 - alpha) * apply(est, 2, stats::sd, na.rm = TRUE)
    lower <- centre - half
    upper <- centre + half
  } else {
    z <- sweep(est, 2, theta) / results$std_errors[!results$failed, , drop = FALSE]
    z[!is.finite(z)] <- NA_real_
    se <- pb_se(results$original)
    missing <- colSums(!is.na(z)) < 2L | is.na(se)
    if (all(missing)) {
      pb_abort("Studentised intervals need the standard errors of the bootstrap refits.")
    }
    if (any(missing)) {
      warning(
        "Studentised limits are `NA` for parameters without a standard error: ",
        paste(names(theta)[missing], collapse = ", "), ".",
        call. = FALSE
      )
    }
    lower <- upper <- rep(NA_real_, length(theta))
    ok <- which(!missing)
    lower[ok] <- theta[ok] - se[ok] * pb_col_quantile(z[, ok, drop = FALSE], 1 - alpha)
    upper[ok] <- theta[ok] - se[ok] * pb_col_quantile(z[, ok, drop = FALSE], alpha)
  }

  data.frame(
    term = names(theta),
    estimate = unname(theta),
    lower = unname(lower),
    upper = unname(upper),
    stringsAsFactors = FALSE
  )
}

pb_col_quantile <- function(x, prob) {
  apply(x, 2, stats::quantile, probs = prob, na.rm = TRUE, names = FALSE)
}
